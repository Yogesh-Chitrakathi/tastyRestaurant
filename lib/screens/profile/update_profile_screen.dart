import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/utils/location_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const UpdateProfileScreen({super.key, required this.currentData});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController houseController;
  late TextEditingController streetController;
  late TextEditingController areaController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController pincodeController;
  late TextEditingController landmarkController;
  late TextEditingController liveLocationController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;

  String gender = "Male";
  bool isLoading = false;
  bool isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.currentData;
    final address = data['address'] as Map<String, dynamic>? ?? {};

    fullNameController = TextEditingController(text: data['fullName'] ?? '');
    phoneController = TextEditingController(text: data['phone'] ?? '');
    houseController = TextEditingController(text: address['house'] ?? '');
    streetController = TextEditingController(text: address['street'] ?? '');
    areaController = TextEditingController(text: address['area'] ?? '');
    cityController = TextEditingController(text: address['city'] ?? '');
    stateController = TextEditingController(text: address['state'] ?? '');
    pincodeController = TextEditingController(text: address['pincode'] ?? '');
    landmarkController = TextEditingController(text: address['landmark'] ?? '');
    liveLocationController = TextEditingController(
      text: address['liveLocation'] ?? '',
    );
    latitudeController = TextEditingController(text: address['latitude'] ?? '');
    longitudeController = TextEditingController(
      text: address['longitude'] ?? '',
    );

    gender = data['gender'] ?? 'Male';
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    houseController.dispose();
    streetController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    landmarkController.dispose();
    liveLocationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> getCurrentLocation() async {
    setState(() => isLocationLoading = true);

    final result = await LocationService.getCurrentLocation(
      context,
      showMessage: showMsg,
    );

    if (result != null) {
      setState(() {
        liveLocationController.text = result.fullAddress;
        latitudeController.text = result.latitude.toString();
        longitudeController.text = result.longitude.toString();

        if (result.placemark != null) {
          final place = result.placemark!;
          houseController.text = place.name ?? "";
          streetController.text = place.thoroughfare ?? "";
          areaController.text = place.subLocality ?? "";
          cityController.text = place.locality ?? "";
          stateController.text = place.administrativeArea ?? "";
          pincodeController.text = place.postalCode ?? "";
          landmarkController.text = place.subThoroughfare ?? "";
        }
      });
      if (result.errorMessage != null) {
        showMsg(result.errorMessage!);
      } else {
        showMsg("Address auto-filled successfully! 🎉");
      }
    }

    setState(() => isLocationLoading = false);
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showMsg("No user signed in.");
        return;
      }

      final uid = user.uid;
      final newPhone = phoneController.text.trim();
      final currentPhone = widget.currentData['phone'] ?? '';

      // Check if phone number is updated and duplicate
      if (newPhone != currentPhone) {
        final phoneCheck = await FirebaseFirestore.instance
            .collection("users")
            .where("phone", isEqualTo: newPhone)
            .get();

        if (phoneCheck.docs.isNotEmpty) {
          showMsg("Phone number is already in use by another account.");
          setState(() => isLoading = false);
          return;
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "fullName": fullNameController.text.trim(),
        "phone": newPhone,
        "gender": gender,
        "address": {
          "house": houseController.text.trim(),
          "street": streetController.text.trim(),
          "area": areaController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
          "landmark": landmarkController.text.trim(),
          "liveLocation": liveLocationController.text.trim(),
          "latitude": latitudeController.text.trim(),
          "longitude": longitudeController.text.trim(),
        },
      });

      // Update Supabase PostgreSQL
      final supabaseUser = sb.Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        await sb.Supabase.instance.client.from('users').update({
          "full_name": fullNameController.text.trim(),
          "phone": newPhone,
          "gender": gender,
          "house": houseController.text.trim(),
          "street": streetController.text.trim(),
          "area": areaController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
          "landmark": landmarkController.text.trim(),
          "live_location": liveLocationController.text.trim(),
          "latitude": latitudeController.text.trim(),
          "longitude": longitudeController.text.trim(),
        }).eq('id', supabaseUser.id);
      }

      showMsg("Profile updated successfully!");
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showMsg("Failed to update profile: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget buildTextField({
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.deepOrange,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Personal details
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Personal Details",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            buildTextField(
                              controller: fullNameController,
                              label: "Full Name",
                              icon: Icons.person,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Name cannot be empty";
                                }
                                if (val.trim().split(" ").length < 2) {
                                  return "Enter full name (min 2 words)";
                                }
                                return null;
                              },
                            ),
                            buildTextField(
                              controller: phoneController,
                              label: "Phone Number",
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Phone number cannot be empty";
                                }
                                if (val.trim().length != 10) {
                                  return "Phone number must be 10 digits";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Gender",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: "Male",
                                  groupValue: gender,
                                  activeColor: Colors.deepOrange,
                                  onChanged: (v) {
                                    if (v != null) setState(() => gender = v);
                                  },
                                ),
                                const Text("Male"),
                                const SizedBox(width: 20),
                                Radio<String>(
                                  value: "Female",
                                  groupValue: gender,
                                  activeColor: Colors.deepOrange,
                                  onChanged: (v) {
                                    if (v != null) setState(() => gender = v);
                                  },
                                ),
                                const Text("Female"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section: Delivery Address
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Delivery Address",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                isLocationLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.deepOrange,
                                        ),
                                      )
                                    : TextButton.icon(
                                        onPressed: getCurrentLocation,
                                        icon: const Icon(
                                          Icons.my_location,
                                          size: 16,
                                          color: Colors.deepOrange,
                                        ),
                                        label: const Text(
                                          "Use GPS",
                                          style: TextStyle(
                                            color: Colors.deepOrange,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            const Divider(height: 10),
                            buildTextField(
                              controller: houseController,
                              label: "House / Building No.",
                              icon: Icons.home,
                            ),
                            buildTextField(
                              controller: streetController,
                              label: "Street / Road Name",
                              icon: Icons.add_road,
                            ),
                            buildTextField(
                              controller: areaController,
                              label: "Area / Locality",
                              icon: Icons.location_city,
                            ),
                            buildTextField(
                              controller: cityController,
                              label: "City",
                              icon: Icons.location_on,
                            ),
                            buildTextField(
                              controller: stateController,
                              label: "State",
                              icon: Icons.map,
                            ),
                            buildTextField(
                              controller: pincodeController,
                              label: "Pincode",
                              icon: Icons.pin,
                              keyboardType: TextInputType.number,
                            ),
                            buildTextField(
                              controller: landmarkController,
                              label: "Landmark",
                              icon: Icons.store,
                            ),
                            const Divider(height: 20),
                            const Text(
                              "Coordinates (Auto-filled by GPS)",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextField(
                                    controller: latitudeController,
                                    label: "Latitude",
                                    icon: Icons.explore_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextField(
                                    controller: longitudeController,
                                    label: "Longitude",
                                    icon: Icons.explore_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
