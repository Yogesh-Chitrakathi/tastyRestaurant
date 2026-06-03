import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const FoodDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final String productId = data['id'] ?? '';
              if (productId.isNotEmpty) {
                final String shareUrl = 'https://tastyRestaurant.com/app/product/$productId';
                Share.share(
                  'Check out this delicious "${data['name']}" from Tasty Restaurant! 🍔\nLink: $shareUrl',
                  subject: 'Delicious food recommendation!',
                );
              }
            },
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ IMAGE
          Image.network(
            data['image'],
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "₹${data['price']}",
                  style: const TextStyle(fontSize: 18, color: Colors.orange),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    Text(data['rating'] ?? "4.2"),
                  ],
                ),

                const SizedBox(height: 15),

                const Text(
                  "Delicious food item with best taste 🍔",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, data);
                    },
                    child: const Text("Add to Cart"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
