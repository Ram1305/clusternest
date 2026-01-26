import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _bhkType;
  String? _genderPreference;
  final _amenitiesController = TextEditingController();
  List<String> _amenities = [];
  List<String> _roomNumbers = [];
  final _roomNumberController = TextEditingController();
  File? _mainImage;
  List<File> _images = [];
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _amenitiesController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {bool isMain = false}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (isMain) {
          _mainImage = File(image.path);
        } else {
          _images.add(File(image.path));
        }
      });
    }
  }

  void _addRoom() {
    if (_roomNumberController.text.isNotEmpty) {
      setState(() {
        _roomNumbers.add(_roomNumberController.text.trim());
        _roomNumberController.clear();
      });
    }
  }

  void _addAmenity() {
    if (_amenitiesController.text.isNotEmpty) {
      setState(() {
        _amenities.add(_amenitiesController.text.trim());
        _amenitiesController.clear();
      });
    }
  }

  Future<void> _selectLocation() async {
    // Show map picker - simplified version
    // In production, use a proper map picker widget
    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: const Text('Map picker would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, const LatLng(12.9716, 77.5946)),
            child: const Text('Use Default'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _mainImage == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addProperty}'),
    );

    // Add headers
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    request.fields['name'] = _nameController.text;
    request.fields['address'] = _addressController.text;
    request.fields['latitude'] = _selectedLocation!.latitude.toString();
    request.fields['longitude'] = _selectedLocation!.longitude.toString();
    request.fields['bhkType'] = _bhkType ?? '1BHK';
    request.fields['genderPreference'] = _genderPreference ?? 'both';
    request.fields['amenities'] = jsonEncode(_amenities);
    request.fields['rooms'] = jsonEncode(_roomNumbers.map((r) => {'roomNumber': r}).toList());

    // Add main image
    if (_mainImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('mainImage', _mainImage!.path),
      );
    }

    // Add additional images
    for (var image in _images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final result = jsonDecode(response.body);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property added successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Home Name *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Home Address *'),
                maxLines: 2,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.map),
                label: Text(_selectedLocation == null
                    ? 'Select Location (Lat/Long)'
                    : 'Location Selected'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _bhkType,
                decoration: const InputDecoration(labelText: 'BHK Type *'),
                items: ['RK', '1BHK', '2BHK', '3BHK', '4BHK']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _bhkType = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _genderPreference,
                decoration: const InputDecoration(labelText: 'Gender Preference *'),
                items: ['male', 'female', 'both']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _genderPreference = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Rooms:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomNumberController,
                      decoration: const InputDecoration(hintText: 'Room Number (e.g., 101)'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addRoom,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _roomNumbers.map((r) => Chip(
                  label: Text(r),
                  onDeleted: () => setState(() => _roomNumbers.remove(r)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Main Image *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _mainImage != null
                  ? Image.file(_mainImage!, height: 150)
                  : const Icon(Icons.image, size: 150),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery, isMain: true),
                icon: const Icon(Icons.photo),
                label: const Text('Pick Main Image'),
              ),
              const SizedBox(height: 16),
              const Text('Additional Images', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ..._images.map((img) => Stack(
                    children: [
                      Image.file(img, height: 100, width: 100),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _images.remove(img)),
                        ),
                      ),
                    ],
                  )),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amenitiesController,
                      decoration: const InputDecoration(hintText: 'Add amenity'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addAmenity,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _amenities.map((a) => Chip(
                  label: Text(a),
                  onDeleted: () => setState(() => _amenities.remove(a)),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
