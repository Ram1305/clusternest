import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'approve_tenant_screen.dart';
import 'add_property_screen.dart';
import 'view_property_screen.dart';
import 'add_bill_screen.dart';
import 'view_payments_screen.dart';
import 'maintenance_requests_screen.dart';
import 'add_ad_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'Approve Tenant',
            Icons.person_add,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApproveTenantScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Add Property',
            Icons.add_home,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'View Property',
            Icons.home,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewPropertyScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Add Bill',
            Icons.receipt,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBillScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'View Payment',
            Icons.payment,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewPaymentsScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Maintenance Request',
            Icons.build,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaintenanceRequestsScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Add Ad Image',
            Icons.image,
            Colors.indigo,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAdScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
