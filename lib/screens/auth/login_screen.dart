import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../home/home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool isLoading = false;

  /// 🔥 EMAIL VALIDATION
  bool isValidEmail(String emailText) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(emailText);
  }

  /// 🔥 LOGIN FUNCTION (IMPROVED)
  Future<void> login() async {
    if (email.text.isEmpty || pass.text.isEmpty) {
      showMsg("Please fill all fields");
      return;
    }

    if (!isValidEmail(email.text)) {
      showMsg("Enter valid email");
      return;
    }

    if (pass.text.length < 6) {
      showMsg("Password must be 6+ characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Firebase Login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      // 2. Supabase Login
      await sb.Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);

      String message = "";

      switch (e.code) {
        case "user-not-found":
          message = "No user found with this email";
          break;
        case "wrong-password":
          message = "Wrong password";
          break;
        case "invalid-email":
          message = "Invalid email format";
          break;
        case "user-disabled":
          message = "User account disabled";
          break;
        default:
          message = "Login failed";
      }

      showMsg(message);
    } on sb.AuthException catch (e) {
      setState(() => isLoading = false);
      // Clean up/Sign out from Firebase if Supabase fails to keep state aligned
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      showMsg("Supabase Login Error: ${e.message}");
    } catch (e) {
      setState(() => isLoading = false);
      showMsg("Something went wrong");
    }
  }

  /// 🔥 FORGOT PASSWORD (REAL EMAIL LINK)
  // Future<void> forgotPassword(String emailText) async {
  //   if (emailText.isEmpty) {
  //     showMsg("Enter email first");
  //     return;
  //   }

  //   if (!isValidEmail(emailText)) {
  //     showMsg("Enter valid email");
  //     return;
  //   }

  //   try {
  //     await FirebaseAuth.instance.sendPasswordResetEmail(
  //       email: emailText.trim(),
  //     );

  //     showMsg("Reset link sent to email 📩");
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == "user-not-found") {
  //       showMsg("No account found with this email");
  //     } else {
  //       showMsg("Failed to send reset email");
  //     }
  //   }
  // }
  Future<void> forgotPassword(String emailText) async {
    if (emailText.isEmpty) {
      showMsg("Enter email first");
      return;
    }

    if (!emailText.contains("@")) {
      showMsg("Enter valid email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailText.trim(),
      );

      /// ✅ ONLY SHOW SUCCESS IF NO ERROR
      showMsg("Reset link sent to email 📩");
    } on FirebaseAuthException catch (e) {
      /// ❌ REAL ERROR HANDLING
      if (e.code == "user-not-found") {
        showMsg("No account found with this email");
      } else if (e.code == "invalid-email") {
        showMsg("Invalid email format");
      } else if (e.code == "too-many-requests") {
        showMsg("Too many requests. Try later");
      } else {
        showMsg("Failed to send reset email");
      }
    } catch (e) {
      showMsg("Something went wrong");
    }
  }

  /// 🔥 MESSAGE SNACKBAR
  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget input(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 100, color: Colors.white),

            const Text(
              "Welcome Back 🍔",
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            input("Email", email),
            input("Password", pass, obscure: true),

            const SizedBox(height: 20),

            /// LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),

            const SizedBox(height: 10),

            /// FORGOT PASSWORD
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    TextEditingController forgotEmail = TextEditingController();

                    return Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Reset Password",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          TextField(
                            controller: forgotEmail,
                            decoration: const InputDecoration(
                              hintText: "Enter your email",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),

                            onPressed: () async {
                              String emailInput = forgotEmail.text.trim();

                              if (emailInput.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Enter email first"),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(
                                context,
                              ); // close bottom sheet FIRST

                              await forgotPassword(
                                emailInput,
                              ); // THEN call Firebase
                            },

                            child: const Text("Send Reset Link"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.white),
              ),
            ),

            /// REGISTER
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RestaurantRegisterScreen(),
                  ),
                );
              },
              child: const Text(
                "New User? Register",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
