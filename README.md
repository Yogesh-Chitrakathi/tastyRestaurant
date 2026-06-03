# 🍔 Tasty Restaurant 🍕

Tasty Restaurant is a modern, feature-rich food delivery and ordering mobile application built with Flutter, Firebase, and deep linking capabilities. The app provides a seamless user journey from secure authentication and live location registration to menu discovery, product sharing, and real-time checkout.

---

## 🌟 Key Features

*   **🔒 Secure Authentication**: Firebase Email & Password authentication featuring a keyboard-aware "Forgot Password" modal sheet that dynamically adjusts layout constraints when the keyboard is focused.
*   **📍 Smart Registration**: Rich multi-field registration screen integrated with the **Geolocator** and **Geocoding** APIs to automatically retrieve and populate the user's house, street, city, state, pincode, and live location coordinate address.
*   **🔍 Interactive Menu & Live Sync**:
    *   Dynamic category filtering (Burgers, Pizza, Snacks, Biryani, Drinks).
    *   Real-time search functionality.
    *   Live Firestore stream-builder for synchronized menu item display.
*   **🛒 Shopping Cart & Checkout**:
    *   State-managed cart to add, remove, and calculate total order costs dynamically.
    *   Automated checkout flow that registers pending orders in the Firestore `orders` collection under the active user's credentials.
*   **🔗 Deep Linking & Share Extension**:
    *   Integrated **App Links** to capture shared food URLs (e.g., `https://tastyRestaurant.com/app/product/<id>`) and automatically route users directly to the specific food item detail screen inside the app.
    *   **Share Plus** social sharing integration on the home and food detail screens.
    *   Pre-configured **Android App Links** (`assetlinks.json`), **iOS Universal Links** (`apple-app-site-association`), and a smart redirection landing page (`redirect.html`) with fallback URLs.

---

## 📂 Project Architecture

```
lib/
│
├── main.dart                      # App entry point, Firebase initialization & Auth listener
├── firebase_options.dart          # Automated Firebase configuration options
│
└── screens/
    ├── splash_screen.dart         # Clean splash screen for app branding
    ├── login_screen.dart          # Secure login & reset password sheet
    ├── registration_screen.dart   # Profile creation & geolocation-assisted address setup
    ├── home_screen.dart           # Food feed, search, category filters, and deep-link listener
    ├── food_detail_screen.dart    # Detailed product display, sharing button & cart addition
    └── cart_screen.dart           # Checkout queue, billing breakdown, and Firestore order creation
```

---

## ⚙️ Deep Linking Setup

The application is structured to handle universal routing via the customized domain **`tastyRestaurant.com`**.

### 📱 Android Configuration
Declared in `android/app/src/main/AndroidManifest.xml`:
*   **Auto-Verify App Links**: Captures `http`/`https` requests directed to `tastyRestaurant.com/app/` to open the app directly.
*   **Custom URI Schemes**: Handled schemes like `tasty://` and `devnectar://` for instant deep-linking and dev debugging.

### 🌐 Web Redirection (`web/redirect.html`)
Contains a responsive Javascript controller to:
*   Automatically extract the `id` from incoming query parameters.
*   Detect the user's OS and attempt a custom intent link: `intent://product?id=...#Intent;scheme=tastyrestaurant;package=com.example.tastyRestaurant2;S.browser_fallback_url=https://devnectar.in/;end`.
*   Provide a fallback redirection to the official website (`https://devnectar.in/`) if the mobile app is not installed.

---

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.5 or newer recommended)
*   Android Studio / Xcode (for emulators and SDK tooling)
*   A Firebase project with Firestore and Authentication enabled

### 1. Clone the repository
```bash
git clone https://github.com/Chitrakathi-2002/tastyRestaurant.git
cd tastyRestaurant
```

### 2. Configure Firebase
1. Set up **Android** and **iOS** applications in your Firebase Console.
2. Download and place:
   *   `google-services.json` inside the `android/app/` directory.
   *   `GoogleService-Info.plist` inside the `ios/Runner/` directory.
3. Configure `firebase_options.dart` inside the `lib/` directory.

### 3. Get dependencies & run
```bash
# Fetch pub packages
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Run the app
flutter run
```
