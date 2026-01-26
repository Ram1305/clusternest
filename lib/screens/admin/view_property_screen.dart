import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ViewPropertyScreen extends StatefulWidget {
  const ViewPropertyScreen({super.key});

  @override
  State<ViewPropertyScreen> createState() => _ViewPropertyScreenState();
}

class _ViewPropertyScreenState extends State<ViewPropertyScreen> {
  List<dynamic> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final response = await ApiService.get(ApiConfig.getProperties);
    if (response['success'] == true) {
      setState(() {
        _properties = response['properties'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Properties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? const Center(child: Text('No properties'))
              : ListView.builder(
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        leading: property['mainImage'] != null
                            ? Image.network(property['mainImage'], width: 60, height: 60)
                            : const Icon(Icons.home),
                        title: Text(property['name'] ?? 'N/A'),
                        subtitle: Text(property['address'] ?? 'N/A'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BHK: ${property['bhkType'] ?? 'N/A'}'),
                                Text('Gender Preference: ${property['genderPreference'] ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                const Text('Rooms:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...(property['rooms'] ?? []).map<Widget>((room) {
                                  return ListTile(
                                    title: Text('Room ${room['roomNumber'] ?? 'N/A'}'),
                                    subtitle: Text('Status: ${room['status'] ?? 'N/A'}'),
                                    trailing: room['currentTenant'] != null
                                        ? Text('Occupied by: ${room['currentTenant']['fullName'] ?? 'N/A'}')
                                        : const Text('Available'),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
