import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'add_edit_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  bool _isLoading = false;

  void _showMsg(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _setDefaultAddress(Map<String, dynamic> address) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final sbUser = sb.Supabase.instance.client.auth.currentUser;
      if (user == null || sbUser == null) return;

      final addressId = address['id'];

      // 1. Reset all addresses is_default to false in Firestore
      final firestoreColl = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("addresses");
      
      final activeAddresses = await firestoreColl.where("is_default", isEqualTo: true).get();
      for (var doc in activeAddresses.docs) {
        await doc.reference.update({'is_default': false});
      }

      // 2. Set this address is_default to true in Firestore
      await firestoreColl.doc(addressId).update({'is_default': true});

      // 3. Reset all in Supabase and set this to true
      await sb.Supabase.instance.client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', sbUser.id);

      await sb.Supabase.instance.client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      // 4. Update the main profile address object in both Firestore and Supabase for backward compatibility
      final mainProfileAddress = {
        'house': address['house'] ?? '',
        'street': address['street'] ?? '',
        'area': address['area'] ?? '',
        'city': address['city'] ?? '',
        'state': address['state'] ?? '',
        'pincode': address['pincode'] ?? '',
        'landmark': address['landmark'] ?? '',
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

      _showMsg("Default address updated successfully! 🎉", isError: false);
    } catch (e) {
      _showMsg("Failed to set default address: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final sbUser = sb.Supabase.instance.client.auth.currentUser;
      if (user == null || sbUser == null) return;

      final addressId = address['id'];

      // 1. Delete from Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("addresses")
          .doc(addressId)
          .delete();

      // 2. Delete from Supabase
      await sb.Supabase.instance.client
          .from('addresses')
          .delete()
          .eq('id', addressId);

      // 3. If it was the default address, clear the main profile address
      if (address['is_default'] == true) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          'address': FieldValue.delete(),
        });

        await sb.Supabase.instance.client.from('users').update({
          'house': null,
          'street': null,
          'area': null,
          'city': null,
          'state': null,
          'pincode': null,
          'landmark': null,
        }).eq('id', sbUser.id);
      }

      _showMsg("Address deleted successfully! 🗑️", isError: false);
    } catch (e) {
      _showMsg("Failed to delete address: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view addresses.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Delivery Addresses"),
        backgroundColor: Colors.deepOrange,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .collection("addresses")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home_outlined, size: 70, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "No delivery addresses added yet.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 85),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isDefault = data['is_default'] ?? false;

                    final addressText = [
                      data['house'] ?? '',
                      data['street'] ?? '',
                      data['area'] ?? '',
                      data['city'] ?? '',
                      data['state'] ?? '',
                      data['pincode'] ?? '',
                    ].where((s) => s.isNotEmpty).join(", ");

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.deepOrange),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDefault ? "Default Address" : "Delivery Address",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDefault ? Colors.deepOrange : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "DEFAULT",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(addressText, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            if (data['landmark'] != null && data['landmark'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Landmark: ${data['landmark']}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isDefault)
                                  TextButton.icon(
                                    onPressed: () => _setDefaultAddress(data),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text("Set as Default"),
                                    style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                                  ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditAddressScreen(addressData: data),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text("Edit"),
                                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteAddress(data),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text("Delete"),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
