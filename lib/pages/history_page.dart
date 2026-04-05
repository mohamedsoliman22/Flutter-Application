import 'package:flutter/material.dart';
import '../database/my_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../utils/csv_export.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MyDatabase _database = MyDatabase();
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _database.initializeDatabase();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId != null) {
        final historyItems = await _database.getHistoryForUser(userId);
        
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

  Future<void> _exportHistoryToCSV() async {
    try {
      // Prepare data for export
      final historyData = _historyItems.map((history) {
        return {
          'id': history['id'],
          'user_id': history['user_id'],
          'date': history['date'].toString(),
          'total': history['total'],
        };
      }).toList();
      
      // Export to CSV
      await CSVExporter.exportHistoryToCSV(context, historyData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error exporting history: ${e.toString()}'),
          ),
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
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportHistoryToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? const Center(child: Text('No order history found'))
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
                          }).toList(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 