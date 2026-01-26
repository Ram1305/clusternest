import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MaintenanceRequestsScreen extends StatelessWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Requests')),
      body: FutureBuilder(
        future: ApiService.get(ApiConfig.getMaintenanceRequests),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final response = snapshot.data as Map<String, dynamic>;
          final requests = response['requests'] ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No maintenance requests'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(request['description'] ?? 'N/A'),
                  subtitle: Text('Priority: ${request['priority'] ?? 'N/A'}'),
                  trailing: Text(request['status'] ?? 'N/A'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
