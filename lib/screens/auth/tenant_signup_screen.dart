import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/razorpay_service.dart';

class TenantSignupScreen extends StatefulWidget {
  const TenantSignupScreen({super.key});

  @override
  State<TenantSignupScreen> createState() => _TenantSignupScreenState();
}

class _TenantSignupScreenState extends State<TenantSignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Tenant Type
  String? _selectedTenantType;

  // Personal Details
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _profilePhoto;

  // Tenant Type Specific
  final _officeNameController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _designationController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _collegeAddressController = TextEditingController();
  final _othersExplanationController = TextEditingController();

  // Aadhaar
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  bool _aadhaarVerified = false;
  File? _aadhaarFront;
  File? _aadhaarBack;

  // Address
  final _houseNoController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyAltPhoneController = TextEditingController();

  // Property Selection
  List<dynamic> _properties = [];
  bool _loadingProperties = false;
  String? _selectedPropertyId;
  String? _selectedRoomId;
  Map<String, dynamic>? _selectedProperty;
  double _paymentAmount = 0.0;

  // Payment
  bool _isProcessingPayment = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay (key should be fetched from backend or config)
    // For now, this needs to be set manually
    // RazorpayService.initialize('YOUR_RAZORPAY_KEY_ID');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _officeNameController.dispose();
    _officeAddressController.dispose();
    _designationController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _businessAddressController.dispose();
    _collegeNameController.dispose();
    _courseNameController.dispose();
    _collegeAddressController.dispose();
    _othersExplanationController.dispose();
    _aadhaarController.dispose();
    _otpController.dispose();
    _houseNoController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyAltPhoneController.dispose();
    RazorpayService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (type == 'profile') {
          _profilePhoto = File(image.path);
        } else if (type == 'aadhaarFront') {
          _aadhaarFront = File(image.path);
        } else if (type == 'aadhaarBack') {
          _aadhaarBack = File(image.path);
        }
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6) {
      final response = await ApiService.post(ApiConfig.verifyOtp, {
        'aadhaarNumber': _aadhaarController.text,
        'otp': _otpController.text,
      });

      if (response['success'] == true) {
        setState(() => _aadhaarVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar verified successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
      }
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _loadingProperties = true);
    final response = await ApiService.get(ApiConfig.getProperties);
    if (response['success'] == true) {
      setState(() {
        _properties = response['properties'] ?? [];
        _loadingProperties = false;
      });
    } else {
      setState(() => _loadingProperties = false);
    }
  }

  void _calculateAge() {
    if (_dobController.text.isNotEmpty) {
      try {
        final dob = DateTime.parse(_dobController.text);
        final age = DateTime.now().difference(dob).inDays ~/ 365;
        _ageController.text = age.toString();
      } catch (e) {
        // Invalid date format
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Calculate payment amount (could be security deposit or fixed fee)
    // For now, using a default amount - should be fetched from property
    _paymentAmount = 5000.0; // Default amount, should be configurable

    final paymentResponse = await authProvider.initiateSignupPayment(
      _selectedPropertyId!,
      _paymentAmount,
    );

    if (paymentResponse == null) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initiate payment')),
      );
      return;
    }

    // Get Razorpay key ID (should be fetched from backend or config)
    // For now, using placeholder - this should be configured
    const razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID'; // TODO: Fetch from backend

    RazorpayService.openCheckout(
      orderId: paymentResponse['order']['id'],
      keyId: razorpayKeyId,
      name: 'ClusterNest Signup',
      description: 'Property Registration Fee',
      amount: _paymentAmount,
      prefillContact: _phoneController.text.trim(),
      prefillEmail: _emailController.text.trim().isEmpty 
          ? 'user@example.com' 
          : _emailController.text.trim(),
      onSuccess: (paymentData) async {
        await _completeSignup(paymentData);
      },
      onError: (error) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $error')),
        );
      },
    );
  }

  Future<void> _completeSignup(Map<String, dynamic> paymentData) async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Prepare signup data with payment info
    final signupData = {
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'fullName': _fullNameController.text.trim(),
      'dateOfBirth': _dobController.text,
      'age': int.tryParse(_ageController.text),
      'gender': _gender,
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'tenantType': _selectedTenantType,
      if (_selectedTenantType == 'working_professional')
        'workingProfessionalDetails': {
          'officeName': _officeNameController.text.trim(),
          'officeAddress': _officeAddressController.text.trim(),
          'designation': _designationController.text.trim(),
        },
      if (_selectedTenantType == 'business')
        'businessDetails': {
          'businessName': _businessNameController.text.trim(),
          'businessType': _businessTypeController.text.trim(),
          'businessAddress': _businessAddressController.text.trim(),
        },
      if (_selectedTenantType == 'student')
        'studentDetails': {
          'collegeName': _collegeNameController.text.trim(),
          'courseName': _courseNameController.text.trim(),
          'collegeAddress': _collegeAddressController.text.trim(),
        },
      if (_selectedTenantType == 'others')
        'othersDetails': {
          'explanation': _othersExplanationController.text.trim(),
        },
      'aadhaarNumber': _aadhaarController.text.trim(),
      'permanentAddress': {
        'houseNo': _houseNoController.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      },
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'relationship': _emergencyRelationshipController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
        'alternatePhone': _emergencyAltPhoneController.text.trim().isEmpty
            ? null
            : _emergencyAltPhoneController.text.trim(),
      },
      'propertyId': _selectedPropertyId,
      'roomId': _selectedRoomId,
      'razorpay_order_id': paymentData['razorpay_order_id'],
      'razorpay_payment_id': paymentData['razorpay_payment_id'],
      'razorpay_signature': paymentData['razorpay_signature'],
    };

    final success = await authProvider.verifySignupPayment(signupData);

    setState(() {
      _isLoading = false;
      _isProcessingPayment = false;
    });

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text('Registration and payment completed successfully. Waiting for admin approval.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed')),
        );
      }
    }
  }

  Widget _buildIllustration() {
    return Container(
      height: 192,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/signup.svg',
          width: 336,
          height: 192,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIllustration(),
                    Text(
                      'Step ${_currentStep + 1}/8',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildTenantTypeStep(),
                          _buildPersonalDetailsStep(),
                          _buildTenantTypeSpecificStep(),
                          _buildAadhaarStep(),
                          _buildAddressStep(),
                          _buildEmergencyContactStep(),
                          _buildPropertySelectionStep(),
                          _buildPaymentStep(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentStep--);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'Previous',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentStep < 7
                                ? () {
                                    // Validate tenant type selection for step 0
                                    if (_currentStep == 0) {
                                      if (_selectedTenantType == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please select a tenant type')),
                                        );
                                        return;
                                      }
                                    }
                                    
                                    if (_formKey.currentState!.validate()) {
                                      if (_currentStep == 1) {
                                        _calculateAge();
                                      }
                                      if (_currentStep == 6) {
                                        _loadProperties();
                                      }
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                      setState(() => _currentStep++);
                                    }
                                  }
                                : _isProcessingPayment || _isLoading
                                    ? null
                                    : _initiatePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _currentStep < 7
                                ? const Text(
                                    'Next',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : _isProcessingPayment || _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Pay Now',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
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
      ),
      floatingActionButton: _currentStep == 6 && _selectedPropertyId != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessingPayment ? null : _initiatePayment,
              backgroundColor: Theme.of(context).colorScheme.primary,
              label: _isProcessingPayment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Pay Now'),
              icon: const Icon(Icons.payment),
            )
          : null,
    );
  }

  Widget _buildTenantTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Tenant Type *',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTenantTypeOption('working_professional', 'Working Professional', Icons.business_center),
          const SizedBox(height: 16),
          _buildTenantTypeOption('business', 'Business', Icons.store),
          const SizedBox(height: 16),
          _buildTenantTypeOption('student', 'Student', Icons.school),
          const SizedBox(height: 16),
          _buildTenantTypeOption('others', 'Others', Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _buildTenantTypeOption(String value, String label, IconData icon) {
    final isSelected = _selectedTenantType == value;
    return InkWell(
      onTap: () => setState(() => _selectedTenantType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth *',
              suffixIcon: Icon(Icons.calendar_today),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _dobController.text = date.toIso8601String().split('T')[0];
                });
              }
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            items: ['male', 'female', 'other']
                .map((g) => DropdownMenuItem(value: g, child: Text(g.toUpperCase())))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email ID *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            obscureText: true,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          const Text('Profile Photo (Optional)'),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_profilePhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_profilePhoto!, height: 80, width: 80, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, size: 40),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery, 'profile'),
                icon: const Icon(Icons.photo),
                label: const Text('Pick Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenantTypeSpecificStep() {
    if (_selectedTenantType == null) {
      return const Center(child: Text('Please select tenant type first'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedTenantType == 'working_professional') ...[
            const Text('Working Professional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _officeNameController,
              decoration: const InputDecoration(
                labelText: 'Office Name *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _officeAddressController,
              decoration: const InputDecoration(
                labelText: 'Office Address *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                labelText: 'Designation *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ] else if (_selectedTenantType == 'business') ...[
            const Text('Business Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessTypeController,
              decoration: const InputDecoration(
                labelText: 'Business Type *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessAddressController,
              decoration: const InputDecoration(
                labelText: 'Business Address *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ] else if (_selectedTenantType == 'student') ...[
            const Text('Student Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _collegeNameController,
              decoration: const InputDecoration(
                labelText: 'College Name *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _collegeAddressController,
              decoration: const InputDecoration(
                labelText: 'College Address *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ] else if (_selectedTenantType == 'others') ...[
            const Text('Other Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _othersExplanationController,
              decoration: const InputDecoration(
                labelText: 'Please explain *',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              maxLines: 5,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAadhaarStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aadhaar eKYC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _aadhaarController,
            decoration: const InputDecoration(
              labelText: 'Aadhaar Number',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify'),
              ),
            ],
          ),
          if (_aadhaarVerified)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('✓ Aadhaar Verified', style: TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 24),
          const Text('Or Manual Upload:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Front'),
                    const SizedBox(height: 8),
                    _aadhaarFront != null
                        ? Image.file(_aadhaarFront!, height: 100)
                        : Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, size: 50),
                          ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery, 'aadhaarFront'),
                      child: const Text('Upload'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('Back'),
                    const SizedBox(height: 8),
                    _aadhaarBack != null
                        ? Image.file(_aadhaarBack!, height: 100)
                        : Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, size: 50),
                          ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery, 'aadhaarBack'),
                      child: const Text('Upload'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Permanent Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _houseNoController,
            decoration: const InputDecoration(
              labelText: 'House No / Street *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'Area / Locality *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stateController,
            decoration: const InputDecoration(
              labelText: 'State *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pincodeController,
            decoration: const InputDecoration(
              labelText: 'Pincode *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Name *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyRelationshipController,
            decoration: const InputDecoration(
              labelText: 'Relationship *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyPhoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyAltPhoneController,
            decoration: const InputDecoration(
              labelText: 'Alternate Phone (Optional)',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelectionStep() {
    if (_properties.isEmpty && !_loadingProperties) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No properties available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProperties,
              child: const Text('Load Properties'),
            ),
          ],
        ),
      );
    }

    if (_loadingProperties) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Property',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: _properties.length,
            itemBuilder: (context, index) {
              final property = _properties[index];
              final isSelected = _selectedPropertyId == property['_id'];
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPropertyId = property['_id'];
                    _selectedProperty = property;
                    // Select first available room if any
                    if (property['rooms'] != null && property['rooms'].isNotEmpty) {
                      final availableRoom = property['rooms'].firstWhere(
                        (room) => room['status'] == 'available',
                        orElse: () => property['rooms'][0],
                      );
                      _selectedRoomId = availableRoom['_id'];
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: property['mainImage'] != null
                              ? CachedNetworkImage(
                                  imageUrl: property['mainImage'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.home, size: 40),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.home, size: 40),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          property['name'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_selectedProperty != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property: ${_selectedProperty!['name'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('Address: ${_selectedProperty!['address'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Registration Fee:'),
                      Text(
                        '₹${_paymentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_paymentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Click "Pay Now" to proceed with payment via Razorpay',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
