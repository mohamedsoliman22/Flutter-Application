# flutter_application

# SportsWear Shop Flutter App

A Flutter mobile application for a sportswear and sports equipment shopping experience.

## Project Description

This app provides a local shopping platform for sports products, including user authentication, product browsing, cart management, checkout, and purchase history. It supports admin access for managing store data and stores user, cart, product, and order history in a local SQLite database.

## Key Features

- User signup and login
- Admin user support (`admin` / `admin` credentials)
- Browse sportswear and equipment products
- Add products to cart and manage cart items
- Checkout flow with order history saving
- View purchase history
- Profile and about screens
- Local persistent storage using SQLite

## Project Structure

- `lib/main.dart` — app entry point and route definitions
- `lib/pages/` — screens for intro, login, signup, main navigation, cart, checkout, profile, history, and admin pages
- `lib/models/product.dart` — data model for products
- `lib/database/my_database.dart` — SQLite database helper for users, products, carts, and order history
- `lib/database/user.dart` — user model and mapping
- `assets/images/` — product and app UI images
