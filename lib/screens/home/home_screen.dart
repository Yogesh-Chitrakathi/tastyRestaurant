import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_links/app_links.dart';
import '../auth/login_screen.dart';
import '../food/food_detail_screen.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All";
  List cart = [];
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkAndSeedFoods();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check initial link if app was opened via link when terminated
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Listen for links while the app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link error: $err");
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint("Received deep link: $uri");
    
    String? productId;
    final segments = uri.pathSegments;
    
    // Parse /app/product/<productId>
    if (segments.length >= 3 && segments[0] == 'app' && segments[1] == 'product') {
      productId = segments[2];
    } else if (uri.queryParameters.containsKey('id')) {
      productId = uri.queryParameters['id'];
    }

    if (productId != null && productId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection("foods")
            .doc(productId)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          final foodData = {
            ...data,
            'id': doc.id,
          };

          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(data: foodData),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint("Error fetching deep linked product: $e");
      }
    }
    
    // Fallback for unknown route: safely stay on home screen
    debugPrint("Unrecognized deep link route or product not found. Staying on Home screen.");
  }

  void _shareProduct(Map<String, dynamic> food) {
    final String productId = food['id'] ?? '';
    if (productId.isEmpty) return;

    final String shareUrl = 'https://tastyRestaurant.com/app/product/$productId';
    Share.share(
      'Check out this delicious "${food['name']}" from Tasty Restaurant! 🍔\nLink: $shareUrl',
      subject: 'Delicious food recommendation!',
    );
  }

  Future<void> _checkAndSeedFoods() async {
    try {
      debugPrint("--- Starting check and seed foods ---");
      final snapshot = await FirebaseFirestore.instance
          .collection("foods")
          .limit(1)
          .get();
      debugPrint("Firestore snapshot docs length: ${snapshot.docs.length}");
      if (snapshot.docs.isEmpty) {
        debugPrint("Foods collection is empty. Seeding local foods...");
        for (var food in localFoods) {
          final ref = await FirebaseFirestore.instance.collection("foods").add(food);
          debugPrint("Added food item: ${food['name']} with ID: ${ref.id}");
        }
        debugPrint("Finished seeding local foods successfully.");
      } else {
        debugPrint("Foods collection is NOT empty. Seeding skipped.");
      }
    } catch (e) {
      debugPrint("Error seeding database: $e");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ✅ "All" option ko list me add kiya taaki startup par items crash na ho
  final List categories = [
    {"emoji": "🍽️", "name": "All"},
    {"emoji": "🍔", "name": "Burger"},
    {"emoji": "🍕", "name": "Pizza"},
    {"emoji": "🍟", "name": "Snacks"},
    {"emoji": "🍚", "name": "Biryani"},
    {"emoji": "🥤", "name": "Drinks"},
  ];

  // ✅ 10 Products with exact matching categories
  final List<Map<String, dynamic>> localFoods = [
    {
      "name": "Cheese Lava Burger",
      "price": "149",
      "category": "Burger",
      "rating": "4.5",
      "image":
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500",
    },
    {
      "name": "Veggie Supreme Pizza",
      "price": "299",
      "category": "Pizza",
      "rating": "4.3",
      "image":
          "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=500",
    },
    {
      "name": "Peri Peri French Fries",
      "price": "99",
      "category": "Snacks",
      "rating": "4.1",
      "image":
          "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?q=80&w=500",
    },
    {
      "name": "Hyderabadi Chicken Biryani",
      "price": "249",
      "category": "Biryani",
      "rating": "4.8",
      "image":
          "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=500",
    },
    {
      "name": "Diet Coca Cola",
      "price": "49",
      "category": "Drinks",
      "rating": "4.0",
      "image":
          "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=500",
    },
    {
      "name": "Crunchy Chicken Burger",
      "price": "179",
      "category": "Burger",
      "rating": "4.4",
      "image":
          "https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?q=80&w=500",
    },
    {
      "name": "Classic Pepperoni Pizza",
      "price": "399",
      "category": "Pizza",
      "rating": "4.6",
      "image":
          "https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=500",
    },
    {
      "name": "Paneer Tikka Kathi Roll",
      "price": "129",
      "category": "Snacks",
      "rating": "4.2",
      "image":
          "https://images.unsplash.com/photo-1626700051175-6518c4793f4f?q=80&w=500",
    },
    {
      "name": "Special Veg Dum Biryani",
      "price": "199",
      "category": "Biryani",
      "rating": "4.3",
      "image":
          "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?q=80&w=500",
    },
    {
      "name": "Premium Cold Coffee",
      "price": "79",
      "category": "Drinks",
      "rating": "4.5",
      "image":
          "https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=500",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ✅ APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tasty Restaurant 🍔",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Find the best food around you",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      // ✅ CART BUTTON (Floating Action Button Fixed)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          final updatedCart = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CartScreen(cartItems: cart),
            ),
          );
          if (updatedCart != null && updatedCart is List) {
            setState(() {
              cart = updatedCart;
            });
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            if (cart.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    "${cart.length}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search your favorite food...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ CATEGORY FILTER
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                var cat = categories[index];
                bool isSelected = selectedCategory == cat["name"];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat["name"];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat["emoji"],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          cat["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("foods").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint("StreamBuilder connection state is waiting...");
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint("StreamBuilder Error: ${snapshot.error}");
                  return Center(child: Text("Error loading food items: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  debugPrint("StreamBuilder has no data or docs are empty.");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No items found in database"),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () async {
                            for (var food in localFoods) {
                              await FirebaseFirestore.instance.collection("foods").add(food);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Demo foods seeded successfully! ✅")),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Seed Demo Foods"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final foodsList = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    ...data,
                    'id': doc.id,
                  };
                }).toList();

                // Live filtering based on selected category & search query
                var filteredFoods = foodsList.where((item) {
                  final matchesCategory = selectedCategory == "All" ||
                      item['category'] == selectedCategory;
                  final matchesSearch = searchQuery.isEmpty ||
                      item['name'].toString().toLowerCase().contains(searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredFoods.isEmpty) {
                  return const Center(
                    child: Text("No items found matching your search"),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredFoods.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    var data = filteredFoods[index];

                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDetailScreen(data: data),
                          ),
                        );

                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            cart.add(result);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${result['name']} added to cart ✅"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image Holder
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(data['image'] ?? ""),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Share Button
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        _shareProduct(data);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.share,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Rating Tag
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            data['rating']?.toString() ?? "4.2",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Details Area
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? "Food Item",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['category'] ?? "General",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "₹${data['price']}",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            cart.add(data);
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "${data['name']} added ✅",
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.orange,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
