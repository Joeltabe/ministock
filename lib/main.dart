import 'package:flutter/material.dart';
import 'package:ministock/Service/AuthService.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/screens/sales/SalesListScreen.dart';
import 'package:ministock/screens/welcome/LoginScreen.dart';
import 'package:ministock/screens/welcome/onboard.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/screens/dashboard_screen.dart';
import 'package:ministock/screens/Articles/inventory_screen.dart';
import 'package:ministock/screens/reports_screen.dart';
import 'package:ministock/screens/sales/sales_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Add this to your main.dart before MaterialApp
final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.indigo,
  colorScheme: ColorScheme.light(
    primary: Color(0xFF004AAD),
    secondary: Color(0xFF00A65A),
    surface: Colors.white,
    background: Colors.grey[50]!,
  ),
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: AppBarTheme(
    elevation: 0,
    backgroundColor: Color(0xFF004AAD),
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.all(8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF004AAD),
    elevation: 4,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color(0xFF004AAD),
    selectionColor: Color(0xFF004AAD).withOpacity(0.4),
    selectionHandleColor: Color(0xFF004AAD),
  ),
);

    return MaterialApp(
      title: 'mini stock',
      theme: appTheme,
      home: AppStartupCheck(),
    );
  }
}
class AppStartupCheck extends StatefulWidget {
  @override
  _AppStartupCheckState createState() => _AppStartupCheckState();
}

class _AppStartupCheckState extends State<AppStartupCheck> {
  bool _isLoading = true;
  bool _needsOnboarding = false;
  User? _loggedInUser;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authService = AuthService();
    final userId = await authService.getLoggedInUserId();
    
    if (userId != null) {
      final user = await _dbHelper.getUserById(userId);
      
      if (user != null) {
        setState(() {
          _loggedInUser = user;
          _isLoading = false;
        });
        return;
      }
    }

    final hasUsers = await _dbHelper.hasAnyUsers();
    setState(() {
      _needsOnboarding = !hasUsers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedInUser != null) {
      return MainNavigation(user: _loggedInUser);
    }

    return _needsOnboarding 
        ? OnboardingFlow(onComplete: _handleOnboardingComplete)
        : LoginScreen(onLoginSuccess: _handleLoginSuccess);
  }

  void _handleOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  void _handleLoginSuccess(User user) {
    setState(() => _loggedInUser = user);
  }
}

class MainNavigation extends StatefulWidget {
  final User? user;

  const MainNavigation({Key? key, this.user}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late Future<User> _currentUserFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _loadCurrentUser();
  }

  Future<User> _loadCurrentUser() async {
    if (widget.user != null) {
      return widget.user!;
    }
    final authService = AuthService();
    final userId = await authService.getLoggedInUserId();
    if (userId == null) {
      throw Exception('No user logged in');
    }
    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _currentUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text('No user data found')),
          );
        }

        final User currentUser = snapshot.data!;

        final List<Widget> _pages = [
          DashboardScreen(user: currentUser),
          InventoryScreen(),
          SalesListScreen(),
          ReportsScreen(),
        ];

        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: _buildModernNavBar(),
        );
      },
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Reports',
            ),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
