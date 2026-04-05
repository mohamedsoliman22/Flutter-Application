import 'package:flutter/material.dart';
import 'my_database.dart';
import 'user.dart';
import '../utils/csv_export.dart';
import '../pages/admin_products_page.dart';
import '../pages/admin_user_history_page.dart';
import '../pages/user_cart_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool isLoading = false;
  List<User> users = List.empty(growable: true);
  final MyDatabase _myDatabase = MyDatabase();

  Future<void> getDataFromDb() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _myDatabase.initializeDatabase();
      users = await _myDatabase.getAllUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error loading users: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> exportUsersToCSV() async {
    try {
      // Convert User objects to Map<String, dynamic>
      final usersData = users.map((user) => user.toMap()).toList();
      
      // Export to CSV
      await CSVExporter.exportUsersToCSV(context, usersData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error exporting users: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> exportAllRelationshipsToCSV() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      await CSVExporter.exportAllRelationshipsToCSV(context);
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error exporting relationships: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> exportUserRelationshipsToCSV(int userId) async {
    try {
      await CSVExporter.exportUserRelationshipsToCSV(context, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error exporting user relationships: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getDataFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Users to CSV',
            onPressed: exportUsersToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation buttons row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.inventory),
                  label: const Text('Products'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminProductsPage(),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export All Relations'),
                  onPressed: exportAllRelationshipsToCSV,
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(child: Text('No users yet'))
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: users[index].isAdmin ? Colors.red : Colors.blue,
                              child: Text(
                                users[index].name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              users[index].name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(users[index].email),
                            trailing: !users[index].isAdmin ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart, color: Colors.blue),
                                  tooltip: 'View Cart',
                                  onPressed: () {
                                    // Navigate to user cart page with user
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserCartPage(user: users[index]),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history, color: Colors.green),
                                  tooltip: 'View Order History',
                                  onPressed: () {
                                    // Navigate to user history page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminUserHistoryPage(user: users[index]),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.table_chart, color: Colors.orange),
                                  tooltip: 'Export User Relationships',
                                  onPressed: () {
                                    if (users[index].id != null) {
                                      exportUserRelationshipsToCSV(users[index].id!);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete User',
                                  onPressed: () async {
                                    try {
                                      await _myDatabase.deleteUser(users[index].id!);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text('${users[index].name} deleted.'),
                                          ),
                                        );
                                        getDataFromDb(); // Refresh the list
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text('Error deleting user: ${e.toString()}'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ) : null,
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/signup');
        },
      ),
    );
  }
} 