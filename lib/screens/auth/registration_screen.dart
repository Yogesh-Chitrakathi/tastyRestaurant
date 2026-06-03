import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/location_service.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({super.key});

  @override
  State<RestaurantRegisterScreen> createState() =>
      _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final house = TextEditingController();
  final street = TextEditingController();
  final area = TextEditingController();
  final city = TextEditingController();
  final stateName = TextEditingController();
  final pincode = TextEditingController();
  final landmark = TextEditingController();
  final locationController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  bool showPass = true;
  bool showConfirm = true;
  bool isLocationLoading = false;

  String gender = "Male";
  bool useForDelivery = false;

  Map<String, bool> interests = {
    "Rajasthani": false,
    "Bihari": false,
    "South Indian": false,
    "Punjabi": false,
    "Chinese": false,
  };

  String locationText = "No location selected";
  double? lat;
  double? lng;

  /// ================= VALIDATION =================
  bool validate() {
    if (fullName.text.trim().split(" ").length < 2) {
      showMsg("Enter full name (min 2 words)");
      return false;
    }

    if (!email.text.contains("@")) {
      showMsg("Enter valid email");
      return false;
    }

    if (phone.text.length != 10) {
      showMsg("Phone must be 10 digits");
      return false;
    }

    if (password.text.length < 6) {
      showMsg("Password must be 6+ chars");
      return false;
    }

    if (password.text != confirmPassword.text) {
      showMsg("Passwords not matching");
      return false;
    }

    return true;
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= LOCATION =================
  Future<void> getCurrentLocation() async {
    setState(() => isLocationLoading = true);

    final result = await LocationService.getCurrentLocation(
      context,
      showMessage: showMsg,
    );

    if (result != null) {
      setState(() {
        lat = result.latitude;
        lng = result.longitude;
        locationText = result.fullAddress;
        locationController.text = result.fullAddress;
        latitudeController.text = result.latitude.toString();
        longitudeController.text = result.longitude.toString();

        if (result.placemark != null) {
          final place = result.placemark!;
          house.text = place.name ?? "";
          street.text = place.thoroughfare ?? "";
          area.text = place.subLocality ?? "";
          city.text = place.locality ?? "";
          stateName.text = place.administrativeArea ?? "";
          pincode.text = place.postalCode ?? "";
          landmark.text = place.subThoroughfare ?? "";
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

  /// ================= REGISTER =================
  Future<void> register() async {
    if (!validate()) return;

    try {
      /// 🔴 PHONE CHECK (Firestore)
      final phoneCheck = await FirebaseFirestore.instance
          .collection("users")
          .where("phone", isEqualTo: phone.text.trim())
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        showMsg("Phone already exists ❌");
        return;
      }

      /// 🔵 EMAIL + AUTH CREATE
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      String uid = userCredential.user!.uid;

      /// 🟢 SAVE DATA
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "fullName": fullName.text.trim(),
        "email": email.text.trim(),
        "phone": phone.text.trim(),
        "gender": gender,
        "interests": interests.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        "address": {
          "house": house.text.trim(),
          "street": street.text.trim(),
          "area": area.text.trim(),
          "city": city.text.trim(),
          "state": stateName.text.trim(),
          "pincode": pincode.text.trim(),
          "landmark": landmark.text.trim(),
          "liveLocation": locationController.text.trim(),
          "latitude": latitudeController.text.trim(),
          "longitude": longitudeController.text.trim(),
        },
        "useForDelivery": useForDelivery,
        "createdAt": DateTime.now(),
      });

      /// ✅ SUCCESS
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
    /// ❌ FIREBASE ERRORS
    on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        showMsg("Email already exists ❌");
      } else if (e.code == "invalid-email") {
        showMsg("Invalid email ❌");
      } else if (e.code == "weak-password") {
        showMsg("Weak password ❌");
      } else {
        showMsg("Registration failed ❌");
      }
    } catch (e) {
      showMsg("Something went wrong ❌");
    }
  }

  /// ================= UI FIELD =================
  Widget field(
    String hint,
    TextEditingController c, {
    bool obscure = false,
    IconData? icon,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepOrange),
          suffixIcon: suffix,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant Register"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// PROFILE
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),

            const SizedBox(height: 20),

            field("Full Name", fullName, icon: Icons.person),
            field("Email", email, icon: Icons.email),
            field("Phone", phone, icon: Icons.phone),

            /// GENDER
            Row(
              children: [
                Radio(
                  value: "Male",
                  groupValue: gender,
                  onChanged: (v) => setState(() => gender = v!),
                ),
                const Text("Male"),
                Radio(
                  value: "Female",
                  groupValue: gender,
                  onChanged: (v) => setState(() => gender = v!),
                ),
                const Text("Female"),
              ],
            ),

            /// INTERESTS
            ...interests.keys.map(
              (e) => CheckboxListTile(
                title: Text(e),
                value: interests[e],
                onChanged: (v) => setState(() => interests[e] = v!),
              ),
            ),

            /// PASSWORD
            field(
              "Password",
              password,
              obscure: showPass,
              icon: Icons.lock,
              suffix: IconButton(
                icon: Icon(showPass ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => showPass = !showPass),
              ),
            ),

            field(
              "Confirm Password",
              confirmPassword,
              obscure: showConfirm,
              icon: Icons.lock,
              suffix: IconButton(
                icon: Icon(
                  showConfirm ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => showConfirm = !showConfirm),
              ),
            ),

            /// ADDRESS
            field("House No", house),
            field("Street", street),
            field("Area", area),
            field("City", city),
            field("State", stateName),
            field("Pincode", pincode),
            field("Landmark", landmark),
            field("Latitude", latitudeController),
            field("Longitude", longitudeController),

            /// LOCATION
            const SizedBox(height: 10),
            isLocationLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : ElevatedButton.icon(
                    onPressed: getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Get Live Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),

            const SizedBox(height: 5),
            Text(
              locationText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            CheckboxListTile(
              title: const Text("Use for delivery"),
              value: useForDelivery,
              onChanged: (v) => setState(() => useForDelivery = v!),
            ),

            const SizedBox(height: 20),

            /// REGISTER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text("Register Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
