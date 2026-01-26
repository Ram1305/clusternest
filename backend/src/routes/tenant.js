const express = require('express');
const router = express.Router();
const tenantController = require('../controllers/tenantController');
const tenantAuth = require('../middleware/tenantAuth');
const upload = require('../middleware/upload');

// Dashboard
router.get('/dashboard', tenantAuth, tenantController.getDashboard);

// Property
router.get('/properties/:id', tenantAuth, tenantController.getProperty);

// Bills
router.get('/bills', tenantAuth, tenantController.getBills);
router.get('/bills/:id', tenantAuth, tenantController.getBill);
router.post('/bills/:id/pay', tenantAuth, tenantController.initiatePayment);

// Payments
router.post('/payments/verify', tenantAuth, tenantController.verifyPayment);
router.get('/payments', tenantAuth, tenantController.getPayments);
router.get('/payments/:id/invoice', tenantAuth, tenantController.downloadInvoice);

// Complaints
router.post('/complaints', tenantAuth, tenantController.raiseComplaint);
router.get('/complaints', tenantAuth, tenantController.getComplaints);

// Maintenance Requests
router.post('/maintenance-requests', tenantAuth, tenantController.createMaintenanceRequest);
router.get('/maintenance-requests', tenantAuth, tenantController.getMaintenanceRequests);

// Requests
router.post('/guest-visit-request', tenantAuth, tenantController.guestVisitRequest);
router.post('/parking-request', tenantAuth, tenantController.parkingRequest);
router.post('/vacation-notice', tenantAuth, tenantController.vacationNotice);

// Notifications
router.get('/notifications', tenantAuth, tenantController.getNotifications);
router.put('/notifications/:id/read', tenantAuth, tenantController.markNotificationRead);

// Messages
router.get('/messages', tenantAuth, tenantController.getMessages);
router.post('/messages', tenantAuth, tenantController.sendMessage);

// Profile
router.get('/profile', tenantAuth, tenantController.getProfile);
router.put('/profile', tenantAuth, upload.single('profilePhoto'), tenantController.updateProfile);

module.exports = router;
