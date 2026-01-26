const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');
const upload = require('../middleware/upload');

// Dashboard
router.get('/dashboard', adminAuth, adminController.getDashboard);

// Tenant Management
router.get('/tenants/pending', adminAuth, adminController.getPendingTenants);
router.post('/tenants/:id/approve', adminAuth, adminController.approveTenant);
router.post('/tenants/:id/reject', adminAuth, adminController.rejectTenant);

// Property Management
router.post('/properties', adminAuth, upload.fields([
  { name: 'mainImage', maxCount: 1 },
  { name: 'images', maxCount: 10 },
]), adminController.addProperty);
router.get('/properties', adminAuth, adminController.getProperties);
router.get('/properties/:id', adminAuth, adminController.getProperty);
router.put('/properties/:id', adminAuth, adminController.updateProperty);
router.delete('/properties/:id', adminAuth, adminController.deleteProperty);

// Bill Management
router.post('/bills', adminAuth, adminController.createBill);
router.get('/bills', adminAuth, adminController.getBills);

// Payment Management
router.get('/payments', adminAuth, adminController.getPayments);

// Maintenance Requests
router.get('/maintenance-requests', adminAuth, adminController.getMaintenanceRequests);

// Ad Management
router.post('/ads', adminAuth, upload.single('image'), adminController.addAd);
router.get('/ads', adminAuth, adminController.getAds);

module.exports = router;
