import 'package:flutter/material.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/screens/Suppliers/supplier_list.dart';
import 'package:ministock/screens/user/UserList.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/screens/Articles/AddEditArticleScreen.dart';
import 'package:ministock/screens/purchase/PurchaseListScreen.dart';
import 'package:ministock/screens/sales/SalesListScreen.dart';
import 'package:ministock/screens/Articles/inventory_screen.dart';
import 'package:ministock/screens/purchase/purchase_screen.dart';
import 'package:ministock/screens/reports_screen.dart';
import 'package:ministock/screens/sales/sales_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({required this.user, Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalItems = 0;
  double todaySales = 0;
  int newOrders = 0;
  bool isLoading = true;

  // Define color scheme
  final Color primaryColor = Color(0xFF283593); // Deep Indigo
  final Color accentColor = Color(0xFF536DFE); // Indigo Accent
  final Color inventoryColor = Color(0xFF2196F3); // Blue
  final Color salesColor = Color(0xFF4CAF50); // Green
  final Color ordersColor = Color(0xFFFF9800); // Orange
  final Color usersColor = Color.fromARGB(255, 228, 210, 53); // Purple
  final Color reportsColor = Color(0xFF9C27B0); // Purple
  final Color cardBackground = Colors.white;
  final Color textDark = Color(0xFF212121);
  final Color textLight = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

int totalSuppliers = 0;
int totalUsers = 0;

Future<void> _fetchDashboardData() async {
  final dbHelper = DatabaseHelper.instance;
  
  // Get total items count
  final articles = await dbHelper.readAllArticles();
  
  // Get today's sales
  final sales = await dbHelper.readAllSales();
  final now = DateTime.now();
  final todaySalesList = sales.where((sale) {
    return sale.saleDate.year == now.year && 
           sale.saleDate.month == now.month && 
           sale.saleDate.day == now.day;
  }).toList();
  
  // Get new orders (purchases from today)
  final purchases = await dbHelper.readAllPurchases();
  final todayPurchases = purchases.where((purchase) {
    return purchase.purchaseDate.year == now.year && 
           purchase.purchaseDate.month == now.month && 
           purchase.purchaseDate.day == now.day;
  }).toList();

  // Get total suppliers
  final suppliers = await dbHelper.readAllSuppliers();
  
  // Get total users
  final users = await dbHelper.readAllUsers();

  setState(() {
    totalItems = articles.length;
    todaySales = todaySalesList.fold(0, (sum, sale) => sum + sale.priceTTC);
    newOrders = todayPurchases.length;
    totalSuppliers = suppliers.length;
    totalUsers = users.length;
    isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light gray background
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: CustomScrollView(
          slivers: [
SliverAppBar(
  expandedHeight: 250,
  pinned: true,
  backgroundColor: primaryColor,
  flexibleSpace: FlexibleSpaceBar(
    collapseMode: CollapseMode.parallax,
    titlePadding: EdgeInsets.only(left: 16, bottom: 16),
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.user.photo != null
                      ? MemoryImage(widget.user.photo!)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: widget.user.photo == null
                      ? Text(
                          widget.user.fullName[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Text(
                  widget.user.fullName.split(' ')[0],
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Mini Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your warehouse efficiently',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),

            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDashboardItem(context, index),
                        childCount: 6,
                      ),
                    ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickAction(
                              icon: Icons.add,
                              label: 'Add Item',
                              color: primaryColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditArticleScreen(),
                                ),
                              ),
                            ),
                            _buildQuickAction(
                              icon: Icons.point_of_sale,
                              label: 'New Sale',
                              color: salesColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesScreen(),
                                ),
                              ),
                            ),
                            _buildQuickAction(
                              icon: Icons.shopping_cart,
                              label: 'New Order',
                              color: ordersColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PurchaseScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ], 
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, int index) {
    final currencyFormat = NumberFormat.currency(symbol: 'CFA ', decimalDigits: 0);
    
final items = [
  {
    'icon': Icons.inventory_rounded,
    'color': inventoryColor,
    'title': 'Total Items',
    'value': totalItems.toString(),
    'route': InventoryScreen(),
  },
  {
    'icon': Icons.trending_up_rounded,
    'color': salesColor,
    'title': 'Today Sales',
    'value': currencyFormat.format(todaySales),
    'route': SalesListScreen(),
  },
  {
    'icon': Icons.local_shipping_rounded,
    'color': ordersColor,
    'title': 'New Orders',
    'value': newOrders.toString(),
    'route': PurchaseListScreen(),
  },
  {
    'icon': Icons.people_rounded, // New supplier icon
    'color': Color(0xFFE91E63), // Pink color for suppliers
    'title': 'Suppliers',
    'value': totalSuppliers.toString(),
    'route': SupplierListPage(), // Make sure to import your SupplierListPage
  },
  {
    'icon': Icons.group_rounded,
    'color': usersColor, // Purple
    'title': 'Employees',
    'value': totalUsers.toString(),
    'route': UserListScreen(), // You'll need to create this
  },
  {
    'icon': Icons.assessment_rounded,
    'color': reportsColor,
    'title': 'Reports',
    'value': 'View',
    'route': ReportsScreen(),
  },
];
    final item = items[index];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => item['route'] as Widget),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
              Text(
                item['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: textLight,
                ),
              ),
              SizedBox(height: 8),
              Text(
                item['value'] as String,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textLight,
            ),
          ),
        ],
      ),
    );
  }
}