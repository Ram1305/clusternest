const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Admin Login
router.post('/admin/login', authController.adminLogin);

// Tenant Signup
router.post('/tenant/signup', authController.tenantSignup);

// Tenant Login
router.post('/tenant/login', authController.tenantLogin);

// Aadhaar OTP Verification
router.post('/tenant/verify-otp', authController.verifyAadhaarOtp);

// Resend Aadhaar OTP
router.post('/tenant/resend-otp', authController.resendAadhaarOtp);

// Signup Payment
router.post('/tenant/signup-payment', authController.initiateSignupPayment);
router.post('/tenant/verify-signup-payment', authController.verifySignupPayment);

module.exports = router;
