import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ApproveTenantScreen extends StatefulWidget {
  const ApproveTenantScreen({super.key});

  @override
  State<ApproveTenantScreen> createState() => _ApproveTenantScreenState();
}

class _ApproveTenantScreenState extends State<ApproveTenantScreen> {
  List<dynamic> _tenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingTenants();
  }

  Future<void> _loadPendingTenants() async {
    final response = await ApiService.get(ApiConfig.pendingTenants);
    if (response['success'] == true) {
      setState(() {
        _tenants = response['tenants'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTenant(String id) async {
    final response = await ApiService.post('${ApiConfig.approveTenant}/$id/approve', {});
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant approved')),
      );
      _loadPendingTenants();
    }
  }

  Future<void> _rejectTenant(String id) async {
    final response = await ApiService.post('${ApiConfig.approveTenant}/$id/reject', {});
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant rejected')),
      );
      _loadPendingTenants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Tenants')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
              ? const Center(child: Text('No pending tenants'))
              : ListView.builder(
                  itemCount: _tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = _tenants[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(tenant['fullName'] ?? 'N/A'),
                        subtitle: Text('Phone: ${tenant['phone'] ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveTenant(tenant['_id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectTenant(tenant['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
