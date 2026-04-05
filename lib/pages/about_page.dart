import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Company Logo
              Image.asset(
                'assets/images/about/logo.jpg',
                height: 120,
              ),
              const SizedBox(height: 30),
              
              // Welcome Message
              const Text(
                'Welcome to SportsWear App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // About Content
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Your premier destination for high-quality sportswear and fitness apparel. '
                  'We combine style, comfort, and performance in every product we offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              
              // Our Story Section
              _buildSection(
                icon: Icons.history,
                title: 'Our Story',
                content: 'Founded in 2023, SportsWear began with a simple mission: to create '
                    'athletic wear that performs as good as it looks. What started as a small '
                    'passion project has grown into a trusted brand for athletes worldwide.',
              ),
              
              // Our Mission Section
              _buildSection(
                icon: Icons.flag,
                title: 'Our Mission',
                content: 'To empower athletes of all levels with premium quality sportswear '
                    'that enhances performance while keeping you comfortable and stylish '
                    'during your workouts.',
              ),
              
              // Values Section
              _buildSection(
                icon: Icons.star,
                title: 'Our Values',
                content: 'Quality • Innovation • Sustainability • Customer Satisfaction',
              ),
              
              const SizedBox(height: 30),
              
              // Contact Information
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Email: support@sportswear.com\n'
                'Phone: +1 (555) 123-4567\n'
                'Hours: Mon-Fri 9AM-5PM',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.orange),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}