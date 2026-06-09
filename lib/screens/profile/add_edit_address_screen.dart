import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/utils/location_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? addressData;

  const AddEditAddressScreen({super.key, this.addressData});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;

  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.addressData ?? {};
    _houseController = TextEditingController(text: data['house'] ?? '');
    _streetController = TextEditingController(text: data['street'] ?? '');
    _areaController = TextEditingController(text: data['area'] ?? '');
    _cityController = TextEditingController(text: data['city'] ?? '');
    _stateController = TextEditingController(text: data['state'] ?? '');
    _pincodeController = TextEditingController(text: data['pincode'] ?? '');
    _landmarkController = TextEditingController(text: data['landmark'] ?? '');
    _isDefault = data['is_default'] ?? false;
  }

  @override
  void dispose() {
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    final result = await LocationService.getCurrentLocation(
      context,
      showMessage: (msg) => _showMsg(msg, isError: true),
    );

    if (result != null) {
      setState(() {
        if (result.placemark != null) {
          final place = result.placemark!;
          _houseController.text = place.name ?? "";
          _streetController.text = place.thoroughfare ?? "";
          _areaController.text = place.subLocality ?? "";
          _cityController.text = place.locality ?? "";
          _stateController.text = place.administrativeArea ?? "";
          _pincodeController.text = place.postalCode ?? "";
          _landmarkController.text = place.subThoroughfare ?? "";
        }
      });
      if (result.errorMessage != null) {
        _showMsg(result.errorMessage!);
      } else {
        _showMsg("Address auto-filled successfully! 🎉", isError: false);
      }
    }

    setState(() => _isLocationLoading = false);
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final sbUser = sb.Supabase.instance.client.auth.currentUser;
      if (user == null || sbUser == null) {
        _showMsg("User session not active.");
        setState(() => _isLoading = false);
        return;
      }

      final addressId = widget.addressData?['id'] ??
          FirebaseFirestore.instance.collection("users").doc(user.uid).collection("addresses").doc().id;

      final addressMap = {
        'id': addressId,
        'house': _houseController.text.trim(),
        'street': _streetController.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'is_default': _isDefault,
      };

      // 1. If is_default is true, clear is_default from all other addresses in Firestore and Supabase
      if (_isDefault) {
        // Firestore update all other addresses of user to is_default = false
        final otherAddressDocs = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("addresses")
            .where("is_default", isEqualTo: true)
            .get();
        for (var doc in otherAddressDocs.docs) {
          if (doc.id != addressId) {
            await doc.reference.update({'is_default': false});
          }
        }

        // Supabase update all other addresses of user to is_default = false
        await sb.Supabase.instance.client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', sbUser.id);

        // Update the main profile address object in both Firestore and Supabase for backward compatibility
        final mainProfileAddress = {
          'house': _houseController.text.trim(),
          'street': _streetController.text.trim(),
          'area': _areaController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'landmark': _landmarkController.text.trim(),
        };

        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          'address': mainProfileAddress,
        });

        await sb.Supabase.instance.client.from('users').update({
          'house': mainProfileAddress['house'],
          'street': mainProfileAddress['street'],
          'area': mainProfileAddress['area'],
          'city': mainProfileAddress['city'],
          'state': mainProfileAddress['state'],
          'pincode': mainProfileAddress['pincode'],
          'landmark': mainProfileAddress['landmark'],
        }).eq('id', sbUser.id);
      }

      // 2. Save/Update in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("addresses")
          .doc(addressId)
          .set(addressMap);

      // 3. Save/Update in Supabase
      final supabaseAddressMap = {
        'id': addressId,
        'user_id': sbUser.id,
        'house': _houseController.text.trim(),
        'street': _streetController.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'is_default': _isDefault,
      };

      await sb.Supabase.instance.client.from('addresses').upsert(supabaseAddressMap);

      _showMsg(
        widget.addressData == null ? "Address added successfully! 🎉" : "Address updated successfully! 🎉",
        isError: false,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMsg("Failed to save address: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepOrange),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.addressData == null ? "Add Address" : "Edit Address";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Address Details",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                _isLocationLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange),
                                      )
                                    : TextButton.icon(
                                        onPressed: _getCurrentLocation,
                                        icon: const Icon(Icons.my_location, size: 16, color: Colors.deepOrange),
                                        label: const Text(
                                          "Use GPS",
                                          style: TextStyle(color: Colors.deepOrange, fontSize: 13),
                                        ),
                                      ),
                              ],
                            ),
                            const Divider(height: 10),
                            _buildTextField(
                              controller: _houseController,
                              label: "House / Building No.",
                              icon: Icons.home,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                            ),
                            _buildTextField(
                              controller: _streetController,
                              label: "Street / Road Name",
                              icon: Icons.add_road,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                            ),
                            _buildTextField(
                              controller: _areaController,
                              label: "Area / Locality",
                              icon: Icons.location_city,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                            ),
                            _buildTextField(
                              controller: _cityController,
                              label: "City",
                              icon: Icons.location_on,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                            ),
                            _buildTextField(
                              controller: _stateController,
                              label: "State",
                              icon: Icons.map,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Field required" : null,
                            ),
                            _buildTextField(
                              controller: _pincodeController,
                              label: "Pincode",
                              icon: Icons.pin,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Field required";
                                }
                                if (val.trim().length < 5) {
                                  return "Enter valid pincode";
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              controller: _landmarkController,
                              label: "Landmark (Optional)",
                              icon: Icons.store,
                            ),
                            const SizedBox(height: 10),
                            CheckboxListTile(
                              title: const Text("Set as default delivery address"),
                              value: _isDefault,
                              activeColor: Colors.deepOrange,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _isDefault = val ?? false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
