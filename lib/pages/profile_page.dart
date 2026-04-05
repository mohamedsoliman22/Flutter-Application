import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/my_database.dart';
import '../database/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  User? currentUser;
  final MyDatabase db = MyDatabase();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    
    if (userEmail != null) {
      await db.initializeDatabase();
      final user = await db.getUserByEmail(userEmail);
      
      if (user != null) {
        setState(() {
          currentUser = user;
          name = user.name;
          email = userEmail;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(String newName, String newEmail) async {
    if (currentUser != null) {
      // Create updated user object
      final updatedUser = User(
        id: currentUser!.id,
        email: newEmail,
        password: currentUser!.password,
        name: newName,
        isAdmin: currentUser!.isAdmin,
        cardNumber: currentUser!.cardNumber,
        cardName: currentUser!.cardName,
        cardExpiry: currentUser!.cardExpiry,
        cardCVV: currentUser!.cardCVV,
      );
      
      // Update in database
      await db.updateUser(updatedUser);
      
      // If email changed, update the shared preferences
      if (email != newEmail) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_email', newEmail);
      }
      
      setState(() {
        name = newName;
        email = newEmail;
        currentUser = updatedUser;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name.isNotEmpty ? name : 'No Name Found',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email.isNotEmpty ? email : 'No Email Found',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<Map<String, String>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                name: name,
                                email: email,
                              ),
                            ),
                          );
                          if (result != null && mounted) {
                            await _updateProfile(result['name']!, result['email']!);
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('current_user_email');
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}