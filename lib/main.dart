import 'package:flutter/material.dart';
import 'SplashScreen.dart';

/// Entry point of the application.
/// Calls runApp() with the root widget MyApp.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
/// Uses a MaterialApp to set up themes and the initial screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application title shown in task switchers
      title: "My Trips",

      // Define the overall theme for the app
      theme: ThemeData(
        // The primary color swatch used throughout the app
        primarySwatch: Colors.blue,

        // Customize the default AppBar appearance
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // AppBar background color
          foregroundColor: Colors.white, // AppBar text/icon color
          centerTitle: true, // Center-align the title text
        ),

        // Customize the default FloatingActionButton appearance
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue, // FAB background color
          foregroundColor: Colors.white, // FAB icon color
        ),
      ),

      // The first screen shown when the app launches
      home: const SplashScreen(),

      // Remove the debug banner that appears in debug mode
      debugShowCheckedModeBanner: false,
    );
  }
}
