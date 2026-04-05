import 'package:flutter/material.dart';
import '../database/my_database.dart';
import '../database/user.dart';
import '../models/product.dart';

class UserCartPage extends StatefulWidget {
  final User user;

  const UserCartPage({super.key, required this.user});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final MyDatabase _database = MyDatabase();
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  double _totalCartValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserCart();
  }

  Future<void> _loadUserCart() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _database.initializeDatabase();
      final cartItems = await _database.getCartItemsWithProductDetails(widget.user.id!);
      
      double total = 0.0;
      for (var item in cartItems) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;
        total += product.price * quantity;
      }

      setState(() {
        _cartItems = cartItems;
        _totalCartValue = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserCart,
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.user.isAdmin ? Colors.red : Colors.blue,
                        radius: 25,
                        child: Text(
                          widget.user.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User ID: ${widget.user.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Role: ${widget.user.isAdmin ? 'Admin' : 'User'}',
                        style: TextStyle(
                          color: widget.user.isAdmin ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Cart Items
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty 
                ? const Center(child: Text('No items in cart', style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final product = item['product'] as Product;
                      final quantity = item['quantity'] as int;
                      final cartId = item['cart_id'] as int;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          leading: Image.asset(
                            product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image, size: 50),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('\$${product.price.toStringAsFixed(2)} × $quantity'),
                          trailing: Text(
                            '\$${(product.price * quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Summary
          if (!_isLoading && _cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Items:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${_cartItems.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Value:',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        '\$${_totalCartValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 