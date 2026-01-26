import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  List<dynamic> _ads = [];
  List<dynamic> _pendingBills = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final response = await ApiService.get(ApiConfig.tenantDashboard);
    if (response['success'] == true) {
      setState(() {
        _ads = response['data']['ads'] ?? [];
        _pendingBills = response['data']['pendingBills'] ?? [];
        _unreadNotifications = response['data']['unreadNotifications'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClusterNest'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Navigate to notifications
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable Ads
            if (_ads.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: _ads.length,
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    return Image.network(
                      ad['image'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, size: 100);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Rent List
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Rent List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (_pendingBills.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No pending bills'),
              )
            else
              ..._pendingBills.map((bill) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Room ${bill['room']?['roomNumber'] ?? 'N/A'}'),
                  subtitle: Text('Due: ${bill['dueDate'] ?? 'N/A'}'),
                  trailing: Text('₹${bill['totalAmount'] ?? '0'}'),
                  onTap: () {
                    // Navigate to bill details
                  },
                ),
              )),
            const SizedBox(height: 16),
            // Grid Menu
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(context, 'Home', Icons.home, Colors.blue),
                _buildMenuCard(context, 'Complaint', Icons.report, Colors.red),
                _buildMenuCard(context, 'Chat', Icons.chat, Colors.green),
                _buildMenuCard(context, 'Profile', Icons.person, Colors.orange),
                _buildMenuCard(context, 'Payments', Icons.payment, Colors.purple),
                _buildMenuCard(context, 'Services', Icons.build, Colors.teal),
                _buildMenuCard(context, 'Requests', Icons.request_quote, Colors.indigo),
                _buildMenuCard(context, 'Communication', Icons.message, Colors.pink),
                _buildMenuCard(context, 'Property & Profile', Icons.business, Colors.brown),
                _buildMenuCard(context, 'Settings', Icons.settings, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Handle navigation
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
