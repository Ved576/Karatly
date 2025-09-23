import 'package:flutter/material.dart';
import 'package:karatly/models/priceModel.dart';
import 'package:karatly/screens/loginScreen.dart';
import 'package:karatly/services/apiService.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for auth state checking

// Import all the screens for the navigation bar.
import 'screens/mainScreen.dart';
import 'screens/buyScreen.dart';
import 'screens/portfolioScreen.dart';
import 'screens/settingScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Gold Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.yellow.shade700,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Colors.yellow.shade700,
          secondary: Colors.yellow.shade600,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.yellow.shade700,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      // ✅ Use AuthWrapper to check authentication state
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const AppHome(),
        '/main': (context) => MainScreen(onNavigatetoBuy: () {}),
        '/login': (context) => LoginScreen(onNavigateToBuy: (){}),
      },
    );
  }
}

// ✅ Added AuthWrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, go to main app
        if (snapshot.hasData && snapshot.data != null) {
          return const AppHome();
        }

        // If user is not logged in, show login screen
        return LoginScreen(onNavigateToBuy: (){});
      },
    );
  }
}

/// This widget now manages the app's root Scaffold, navigation, AND the live price state.
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int _selectedIndex = 0;

  // --- STATE LIFTED UP ---
  // The state for the current price now lives here, in the common parent.
  final GoldApiService _apiService = GoldApiService();
  GoldPrice? _goldPrice;
  bool _isLoadingPrice = true;
  String _priceErrorMessage = '';

  @override
  void initState() {
    super.initState();
    // Fetch the price as soon as the app shell loads.
    _fetchGoldPrice();
  }

  /// The price fetching logic now resides in the parent widget.
  Future<void> _fetchGoldPrice() async {
    try {
      final newPriceData = await _apiService.fetchGoldPrice();
      if (mounted) {
        setState(() {
          _goldPrice = newPriceData;
          _isLoadingPrice = false;
          _priceErrorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _priceErrorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoadingPrice = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The list of screens is now built inside the build method so it can
    // access the latest state (_goldPrice).
    final List<Widget> screens = <Widget>[
      MainScreen(onNavigatetoBuy: () => _onItemTapped(1)),
      BuyScreen(priceData: _goldPrice),
      PortfolioScreen(
        priceData: _goldPrice,
        onNavigatetoBuy: () => _onItemTapped(1),
      ),
      const Settings(),
    ];

    return Scaffold(
      // The body of the Scaffold is the currently selected screen.
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee),
            label: 'Buy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
