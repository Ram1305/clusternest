import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ViewPaymentsScreen extends StatelessWidget {
  const ViewPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Payments')),
      body: FutureBuilder(
        future: ApiService.get(ApiConfig.getPayments),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final response = snapshot.data as Map<String, dynamic>;
          final payments = response['payments'] ?? [];
          if (payments.isEmpty) {
            return const Center(child: Text('No payments'));
          }
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('₹${payment['amount'] ?? '0'}'),
                  subtitle: Text('Date: ${payment['paymentDate'] ?? 'N/A'}'),
                  trailing: Text(payment['status'] ?? 'N/A'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
