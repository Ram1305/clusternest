import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  int _currentStep = 0;
  List<dynamic> _properties = [];
  String? _selectedPropertyId;
  List<dynamic> _rooms = [];
  String? _selectedRoomId;
  String? _selectedTenantId;
  final _basicRentController = TextEditingController();
  final _ebBillController = TextEditingController();
  final _internetController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _foodController = TextEditingController();
  final _fineController = TextEditingController();
  final _otherController = TextEditingController();
  final _dueDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _basicRentController.dispose();
    _ebBillController.dispose();
    _internetController.dispose();
    _maintenanceController.dispose();
    _foodController.dispose();
    _fineController.dispose();
    _otherController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    final response = await ApiService.get(ApiConfig.getProperties);
    if (response['success'] == true) {
      setState(() {
        _properties = response['properties'] ?? [];
      });
    }
  }

  Future<void> _loadRooms(String propertyId) async {
    final response = await ApiService.get('${ApiConfig.getProperties}/$propertyId');
    if (response['success'] == true) {
      setState(() {
        _rooms = response['property']['rooms'] ?? [];
      });
    }
  }

  double _calculateTotal() {
    return (double.tryParse(_basicRentController.text) ?? 0) +
        (double.tryParse(_ebBillController.text) ?? 0) +
        (double.tryParse(_internetController.text) ?? 0) +
        (double.tryParse(_maintenanceController.text) ?? 0) +
        (double.tryParse(_foodController.text) ?? 0) +
        (double.tryParse(_fineController.text) ?? 0) +
        (double.tryParse(_otherController.text) ?? 0);
  }

  Future<void> _submit() async {
    if (_selectedPropertyId == null || _selectedRoomId == null || _selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select property and room')),
      );
      return;
    }

    final response = await ApiService.post(ApiConfig.createBill, {
      'propertyId': _selectedPropertyId,
      'roomId': _selectedRoomId,
      'tenantId': _selectedTenantId,
      'dueDate': _dueDateController.text,
      'charges': {
        'basicRent': double.tryParse(_basicRentController.text) ?? 0,
        'ebBill': double.tryParse(_ebBillController.text) ?? 0,
        'internetPayment': double.tryParse(_internetController.text) ?? 0,
        'maintenanceCharge': double.tryParse(_maintenanceController.text) ?? 0,
        'foodCharge': double.tryParse(_foodController.text) ?? 0,
        'fineCharges': double.tryParse(_fineController.text) ?? 0,
        'otherCharges': double.tryParse(_otherController.text) ?? 0,
      },
    });

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill created successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
            if (_currentStep == 1 && _selectedPropertyId != null) {
              _loadRooms(_selectedPropertyId!);
            }
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Select Home'),
            content: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                final isSelected = _selectedPropertyId == property['_id'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPropertyId = property['_id'];
                    });
                  },
                  child: Card(
                    color: isSelected ? Colors.orange : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, size: 40),
                        Text(property['name'] ?? 'N/A'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Step(
            title: const Text('Select Room'),
            content: _selectedPropertyId == null
                ? const Text('Please select a property first')
                : _rooms.isEmpty
                    ? const CircularProgressIndicator()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          final isSelected = _selectedRoomId == room['_id'];
                          return ListTile(
                            title: Text('Room ${room['roomNumber'] ?? 'N/A'}'),
                            subtitle: Text('Status: ${room['status'] ?? 'N/A'}'),
                            trailing: isSelected ? const Icon(Icons.check) : null,
                            onTap: () {
                              setState(() {
                                _selectedRoomId = room['_id'];
                                _selectedTenantId = room['currentTenant']?['_id'];
                              });
                            },
                          );
                        },
                      ),
          ),
          Step(
            title: const Text('Enter Charges'),
            content: Column(
              children: [
                TextFormField(
                  controller: _basicRentController,
                  decoration: const InputDecoration(labelText: 'Basic Rent'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _ebBillController,
                  decoration: const InputDecoration(labelText: 'EB Bill'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _internetController,
                  decoration: const InputDecoration(labelText: 'Internet Payment'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _maintenanceController,
                  decoration: const InputDecoration(labelText: 'Maintenance Charge'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _foodController,
                  decoration: const InputDecoration(labelText: 'Food Charge'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _fineController,
                  decoration: const InputDecoration(labelText: 'Fine Charges'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _otherController,
                  decoration: const InputDecoration(labelText: 'Other Charges'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      _dueDateController.text = date.toIso8601String().split('T')[0];
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
