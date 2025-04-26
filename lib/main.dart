import 'package:flutter/material.dart';
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
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    DashboardScreen(),
    InventoryScreen(),
    SalesScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildModernNavBar(),
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