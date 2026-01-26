class ApiConfig {
  // Update this with your backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth Endpoints
  static const String adminLogin = '/auth/admin/login';
  static const String tenantSignup = '/auth/tenant/signup';
  static const String tenantLogin = '/auth/tenant/login';
  static const String verifyOtp = '/auth/tenant/verify-otp';
  static const String resendOtp = '/auth/tenant/resend-otp';
  static const String signupPayment = '/auth/tenant/signup-payment';
  static const String verifySignupPayment = '/auth/tenant/verify-signup-payment';
  
  // Admin Endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String pendingTenants = '/admin/tenants/pending';
  static const String approveTenant = '/admin/tenants';
  static const String addProperty = '/admin/properties';
  static const String getProperties = '/admin/properties';
  static const String createBill = '/admin/bills';
  static const String getPayments = '/admin/payments';
  static const String getMaintenanceRequests = '/admin/maintenance-requests';
  static const String addAd = '/admin/ads';
  static const String getAds = '/admin/ads';
  
  // Tenant Endpoints
  static const String tenantDashboard = '/tenant/dashboard';
  static const String getBills = '/tenant/bills';
  static const String initiatePayment = '/tenant/bills';
  static const String verifyPayment = '/tenant/payments/verify';
  static const String getPaymentHistory = '/tenant/payments';
  static const String raiseComplaint = '/tenant/complaints';
  static const String getComplaints = '/tenant/complaints';
  static const String createMaintenanceRequest = '/tenant/maintenance-requests';
  static const String getMaintenanceRequestsTenant = '/tenant/maintenance-requests';
  static const String guestVisitRequest = '/tenant/guest-visit-request';
  static const String parkingRequest = '/tenant/parking-request';
  static const String vacationNotice = '/tenant/vacation-notice';
  static const String getNotifications = '/tenant/notifications';
  static const String markNotificationRead = '/tenant/notifications';
  static const String getMessages = '/tenant/messages';
  static const String sendMessage = '/tenant/messages';
  static const String getProfile = '/tenant/profile';
  static const String updateProfile = '/tenant/profile';
}
