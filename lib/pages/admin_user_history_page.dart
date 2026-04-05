import 'package:flutter/material.dart';
import '../database/user.dart';
import '../database/my_database.dart';
import '../models/product.dart';

class AdminUserHistoryPage extends StatefulWidget {
  final User user;
  
  const AdminUserHistoryPage({super.key, required this.user});

  @override
  State<AdminUserHistoryPage> createState() => _AdminUserHistoryPageState();
}

class _AdminUserHistoryPageState extends State<AdminUserHistoryPage> {
  final MyDatabase _database = MyDatabase();
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserHistory();
  }

  Future<void> _loadUserHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _database.initializeDatabase();
      if (widget.user.id != null) {
        final historyItems = await _database.getHistoryForUser(widget.user.id!);
        
        if (mounted) {
          setState(() {
            _historyItems = historyItems;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name}\'s Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? const Center(child: Text('No order history found for this user'))
              : ListView.builder(
                  itemCount: _historyItems.length,
                  itemBuilder: (context, index) {
                    final historyItem = _historyItems[index];
                    final date = historyItem['date'] as DateTime;
                    final total = historyItem['total'] as double;
                    final items = historyItem['items'] as List<Map<String, dynamic>>;
                    
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text(
                          'Order #${historyItem['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: ${_formatDate(date)}\n'
                          'Total: \$${total.toStringAsFixed(2)}',
                        ),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'Order Items',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ...items.map((item) {
                            final product = item['product'] as Product;
                            final quantity = item['quantity'] as int;
                            final price = item['price'] as double;
                            
                            return ListTile(
                              leading: Image.asset(
                                product.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 40),
                              ),
                              title: Text(product.name),
                              subtitle: Text('\$${price.toStringAsFixed(2)} × $quantity'),
                              trailing: Text(
                                '\$${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 