const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const Tenant = require('../models/Tenant');

// Generate JWT Token
const generateToken = (id, userType) => {
  return jwt.sign({ id, userType }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '30d',
  });
};

// Admin Login
exports.adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const admin = await Admin.findOne({ email: email.toLowerCase() });

    if (!admin) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await admin.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = generateToken(admin._id, 'admin');

    res.json({
      success: true,
      token,
      admin: {
        id: admin._id,
        email: admin.email,
        name: admin.name,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Tenant Signup
exports.tenantSignup = async (req, res) => {
  try {
    const {
      phone,
      password,
      fullName,
      dateOfBirth,
      age,
      gender,
      email,
      // Tenant Type
      tenantType,
      workingProfessionalDetails,
      businessDetails,
      studentDetails,
      othersDetails,
      // Aadhaar
      aadhaarNumber,
      // Address
      permanentAddress,
      officeAddress,
      // Emergency Contact
      emergencyContact,
      // Additional
      occupation,
      companyName,
      familyMembers,
      vehicleDetails,
      // Agreement
      propertyId,
      roomId,
      agreementStartDate,
      agreementEndDate,
      monthlyRent,
      securityDeposit,
      maintenanceAmount,
    } = req.body;

    // Check if tenant already exists
    const existingTenant = await Tenant.findOne({ phone });
    if (existingTenant) {
      return res.status(400).json({ message: 'Tenant with this phone number already exists' });
    }

    // Validate tenant type-specific fields
    if (tenantType === 'working_professional') {
      if (!workingProfessionalDetails?.officeName || !workingProfessionalDetails?.officeAddress || !workingProfessionalDetails?.designation) {
        return res.status(400).json({ message: 'Working professional details are required' });
      }
    } else if (tenantType === 'business') {
      if (!businessDetails?.businessName || !businessDetails?.businessType || !businessDetails?.businessAddress) {
        return res.status(400).json({ message: 'Business details are required' });
      }
    } else if (tenantType === 'student') {
      if (!studentDetails?.collegeName || !studentDetails?.courseName || !studentDetails?.collegeAddress) {
        return res.status(400).json({ message: 'Student details are required' });
      }
    } else if (tenantType === 'others') {
      if (!othersDetails?.explanation) {
        return res.status(400).json({ message: 'Explanation is required for others category' });
      }
    }

    // Create tenant
    const tenant = await Tenant.create({
      phone,
      password,
      fullName,
      dateOfBirth,
      age,
      gender,
      email,
      tenantType,
      workingProfessionalDetails,
      businessDetails,
      studentDetails,
      othersDetails,
      aadhaarNumber,
      permanentAddress,
      officeAddress,
      emergencyContact,
      occupation,
      companyName,
      familyMembers,
      vehicleDetails,
      registrationStatus: 'pending',
      paymentStatus: 'pending',
      currentProperty: propertyId,
      currentRoom: roomId,
    });

    // Create agreement if provided
    if (propertyId && roomId) {
      const Agreement = require('../models/Agreement');
      await Agreement.create({
        tenant: tenant._id,
        property: propertyId,
        room: roomId,
        startDate: agreementStartDate,
        endDate: agreementEndDate,
        monthlyRent,
        securityDeposit,
        maintenanceAmount,
      });
    }

    res.status(201).json({
      success: true,
      message: 'Tenant registered successfully. Waiting for admin approval.',
      tenant: {
        id: tenant._id,
        phone: tenant.phone,
        fullName: tenant.fullName,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Tenant Login
exports.tenantLogin = async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ message: 'Please provide phone and password' });
    }

    const tenant = await Tenant.findOne({ phone });

    if (!tenant) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (tenant.registrationStatus !== 'approved') {
      return res.status(403).json({ message: 'Your registration is pending approval' });
    }

    const isMatch = await tenant.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = generateToken(tenant._id, 'tenant');

    res.json({
      success: true,
      token,
      tenant: {
        id: tenant._id,
        phone: tenant.phone,
        fullName: tenant.fullName,
        email: tenant.email,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Aadhaar OTP Verification (Simulated)
exports.verifyAadhaarOtp = async (req, res) => {
  try {
    const { aadhaarNumber, otp } = req.body;

    // Simulated OTP verification
    // In production, integrate with real Aadhaar API
    if (otp === '123456' || otp.length === 6) {
      res.json({
        success: true,
        message: 'Aadhaar verified successfully',
      });
    } else {
      res.status(400).json({ message: 'Invalid OTP' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Resend Aadhaar OTP (Simulated)
exports.resendAadhaarOtp = async (req, res) => {
  try {
    const { aadhaarNumber } = req.body;

    // Simulated OTP generation
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    res.json({
      success: true,
      message: 'OTP sent successfully',
      otp, // In production, send via SMS/Email, don't return in response
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Initiate Signup Payment
exports.initiateSignupPayment = async (req, res) => {
  try {
    const { propertyId, amount } = req.body;

    if (!propertyId || !amount) {
      return res.status(400).json({ message: 'Property ID and amount are required' });
    }

    const { createOrder } = require('../services/razorpayService');
    const receipt = `signup_${propertyId}_${Date.now()}`;
    const orderResult = await createOrder(amount, 'INR', receipt);

    if (!orderResult.success) {
      return res.status(500).json({ message: 'Payment initiation failed', error: orderResult.error });
    }

    res.json({
      success: true,
      order: orderResult.order,
      propertyId,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Verify Signup Payment and Complete Registration
exports.verifySignupPayment = async (req, res) => {
  try {
    const {
      phone,
      password,
      fullName,
      dateOfBirth,
      age,
      gender,
      email,
      tenantType,
      workingProfessionalDetails,
      businessDetails,
      studentDetails,
      othersDetails,
      aadhaarNumber,
      permanentAddress,
      officeAddress,
      emergencyContact,
      occupation,
      companyName,
      familyMembers,
      vehicleDetails,
      propertyId,
      roomId,
      agreementStartDate,
      agreementEndDate,
      monthlyRent,
      securityDeposit,
      maintenanceAmount,
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
    } = req.body;

    // Verify payment
    const { verifyPayment: verifyRazorpayPayment } = require('../services/razorpayService');
    const isValid = verifyRazorpayPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);

    if (!isValid) {
      return res.status(400).json({ message: 'Payment verification failed' });
    }

    // Check if tenant already exists
    const existingTenant = await Tenant.findOne({ phone });
    if (existingTenant) {
      return res.status(400).json({ message: 'Tenant with this phone number already exists' });
    }

    // Validate tenant type-specific fields
    if (tenantType === 'working_professional') {
      if (!workingProfessionalDetails?.officeName || !workingProfessionalDetails?.officeAddress || !workingProfessionalDetails?.designation) {
        return res.status(400).json({ message: 'Working professional details are required' });
      }
    } else if (tenantType === 'business') {
      if (!businessDetails?.businessName || !businessDetails?.businessType || !businessDetails?.businessAddress) {
        return res.status(400).json({ message: 'Business details are required' });
      }
    } else if (tenantType === 'student') {
      if (!studentDetails?.collegeName || !studentDetails?.courseName || !studentDetails?.collegeAddress) {
        return res.status(400).json({ message: 'Student details are required' });
      }
    } else if (tenantType === 'others') {
      if (!othersDetails?.explanation) {
        return res.status(400).json({ message: 'Explanation is required for others category' });
      }
    }

    // Create tenant with payment details
    const tenant = await Tenant.create({
      phone,
      password,
      fullName,
      dateOfBirth,
      age,
      gender,
      email,
      tenantType,
      workingProfessionalDetails,
      businessDetails,
      studentDetails,
      othersDetails,
      aadhaarNumber,
      permanentAddress,
      officeAddress,
      emergencyContact,
      occupation,
      companyName,
      familyMembers,
      vehicleDetails,
      registrationStatus: 'pending',
      paymentStatus: 'completed',
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      currentProperty: propertyId,
      currentRoom: roomId,
    });

    // Create agreement if provided
    if (propertyId && roomId) {
      const Agreement = require('../models/Agreement');
      await Agreement.create({
        tenant: tenant._id,
        property: propertyId,
        room: roomId,
        startDate: agreementStartDate,
        endDate: agreementEndDate,
        monthlyRent,
        securityDeposit,
        maintenanceAmount,
      });
    }

    res.status(201).json({
      success: true,
      message: 'Registration and payment completed successfully. Waiting for admin approval.',
      tenant: {
        id: tenant._id,
        phone: tenant.phone,
        fullName: tenant.fullName,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
