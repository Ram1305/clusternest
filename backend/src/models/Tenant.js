const mongoose = require('mongoose');

const tenantSchema = new mongoose.Schema({
  // Authentication
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  otp: {
    type: String,
  },
  otpExpiry: {
    type: Date,
  },

  // Tenant Type
  tenantType: {
    type: String,
    enum: ['working_professional', 'business', 'student', 'others'],
    trim: true,
  },
  workingProfessionalDetails: {
    officeName: { type: String, trim: true },
    officeAddress: { type: String, trim: true },
    designation: { type: String, trim: true },
  },
  businessDetails: {
    businessName: { type: String, trim: true },
    businessType: { type: String, trim: true },
    businessAddress: { type: String, trim: true },
  },
  studentDetails: {
    collegeName: { type: String, trim: true },
    courseName: { type: String, trim: true },
    collegeAddress: { type: String, trim: true },
  },
  othersDetails: {
    explanation: { type: String, trim: true },
  },

  // Personal Details
  fullName: {
    type: String,
    required: true,
    trim: true,
  },
  dateOfBirth: {
    type: Date,
    required: true,
  },
  age: {
    type: Number,
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other'],
    required: true,
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
  },
  profilePhoto: {
    type: String, // Cloudinary URL
  },

  // Aadhaar Details
  aadhaarNumber: {
    type: String,
    trim: true,
  },
  aadhaarVerified: {
    type: Boolean,
    default: false,
  },
  aadhaarFrontImage: {
    type: String, // Cloudinary URL
  },
  aadhaarBackImage: {
    type: String, // Cloudinary URL
  },
  aadhaarOtp: {
    type: String,
  },
  aadhaarOtpExpiry: {
    type: Date,
  },

  // Address Details
  permanentAddress: {
    houseNo: { type: String, trim: true },
    area: { type: String, trim: true },
    city: { type: String, trim: true },
    state: { type: String, trim: true },
    pincode: { type: String, trim: true },
  },
  officeAddress: {
    type: String,
    trim: true,
  },

  // Emergency Contact
  emergencyContact: {
    name: { type: String, trim: true },
    relationship: { type: String, trim: true },
    phone: { type: String, trim: true },
    alternatePhone: { type: String, trim: true },
  },

  // Additional Details
  occupation: {
    type: String,
    trim: true,
  },
  companyName: {
    type: String,
    trim: true,
  },
  familyMembers: {
    type: Number,
    default: 0,
  },
  vehicleDetails: {
    type: { type: String, trim: true },
    number: { type: String, trim: true },
  },

  // Payment Status
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'failed'],
    default: 'pending',
  },
  razorpayOrderId: {
    type: String,
  },
  razorpayPaymentId: {
    type: String,
  },

  // Status
  registrationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  accountStatus: {
    type: String,
    enum: ['active', 'inactive', 'suspended'],
    default: 'active',
  },

  // Current Property/Room Assignment
  currentProperty: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Property',
  },
  currentRoom: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
  },
}, {
  timestamps: true,
});

// Hash password before saving
tenantSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const bcrypt = require('bcryptjs');
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password method
tenantSchema.methods.comparePassword = async function (candidatePassword) {
  const bcrypt = require('bcryptjs');
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Tenant', tenantSchema);
