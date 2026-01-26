const Property = require('../models/Property');
const Room = require('../models/Room');
const Tenant = require('../models/Tenant');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');
const MaintenanceRequest = require('../models/MaintenanceRequest');
const Ad = require('../models/Ad');
const Agreement = require('../models/Agreement');

// Dashboard Stats
exports.getDashboard = async (req, res) => {
  try {
    const pendingTenants = await Tenant.countDocuments({ registrationStatus: 'pending' });
    const totalProperties = await Property.countDocuments();
    const totalRooms = await Room.countDocuments();
    const occupiedRooms = await Room.countDocuments({ status: 'occupied' });
    const pendingBills = await Bill.countDocuments({ status: 'pending' });
    const totalPayments = await Payment.countDocuments({ status: 'success' });
    const pendingMaintenance = await MaintenanceRequest.countDocuments({ status: 'pending' });

    res.json({
      success: true,
      stats: {
        pendingTenants,
        totalProperties,
        totalRooms,
        occupiedRooms,
        availableRooms: totalRooms - occupiedRooms,
        pendingBills,
        totalPayments,
        pendingMaintenance,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Pending Tenants
exports.getPendingTenants = async (req, res) => {
  try {
    const tenants = await Tenant.find({ registrationStatus: 'pending' })
      .select('-password')
      .populate('currentProperty', 'name address')
      .populate('currentRoom', 'roomNumber');

    res.json({
      success: true,
      tenants,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Approve Tenant
exports.approveTenant = async (req, res) => {
  try {
    const { id } = req.params;

    const tenant = await Tenant.findById(id);
    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }

    tenant.registrationStatus = 'approved';
    await tenant.save();

    // If tenant has assigned room, update room status
    if (tenant.currentRoom) {
      const room = await Room.findById(tenant.currentRoom);
      if (room) {
        room.status = 'occupied';
        room.currentTenant = tenant._id;
        await room.save();
      }
    }

    res.json({
      success: true,
      message: 'Tenant approved successfully',
      tenant,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Reject Tenant
exports.rejectTenant = async (req, res) => {
  try {
    const { id } = req.params;

    const tenant = await Tenant.findById(id);
    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }

    tenant.registrationStatus = 'rejected';
    await tenant.save();

    res.json({
      success: true,
      message: 'Tenant rejected',
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Add Property
exports.addProperty = async (req, res) => {
  try {
    const {
      name,
      address,
      latitude,
      longitude,
      bhkType,
      amenities,
      genderPreference,
      rooms,
    } = req.body;

    const { uploadToCloudinary, uploadMultipleToCloudinary } = require('../services/cloudinaryService');

    // Upload main image
    let mainImage = '';
    if (req.files && req.files.mainImage) {
      mainImage = await uploadToCloudinary(req.files.mainImage[0].buffer, 'clusternest/properties');
    }

    // Upload additional images
    let images = [];
    if (req.files && req.files.images) {
      images = await uploadMultipleToCloudinary(req.files.images, 'clusternest/properties');
    }

    const property = await Property.create({
      name,
      address,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      bhkType,
      mainImage,
      images,
      amenities: amenities || [],
      genderPreference: genderPreference || 'both',
    });

    // Create rooms
    if (rooms && Array.isArray(rooms)) {
      const roomPromises = rooms.map(async (roomData) => {
        const room = await Room.create({
          property: property._id,
          roomNumber: roomData.roomNumber,
          monthlyRent: roomData.monthlyRent || 0,
          securityDeposit: roomData.securityDeposit || 0,
          maintenanceAmount: roomData.maintenanceAmount || 0,
          status: 'available',
        });
        return room._id;
      });

      const roomIds = await Promise.all(roomPromises);
      property.rooms = roomIds;
      await property.save();
    }

    res.status(201).json({
      success: true,
      property,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get All Properties
exports.getProperties = async (req, res) => {
  try {
    const properties = await Property.find()
      .populate('rooms')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      properties,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Property Details
exports.getProperty = async (req, res) => {
  try {
    const { id } = req.params;

    const property = await Property.findById(id)
      .populate({
        path: 'rooms',
        populate: {
          path: 'currentTenant',
          select: 'fullName phone email',
        },
      });

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    res.json({
      success: true,
      property,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update Property
exports.updateProperty = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const property = await Property.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    res.json({
      success: true,
      property,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Delete Property
exports.deleteProperty = async (req, res) => {
  try {
    const { id } = req.params;

    const property = await Property.findById(id);
    if (!property) {
      return res.status(404).json({ message: 'Property not found' });
    }

    // Delete all rooms
    await Room.deleteMany({ property: id });

    await Property.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Property deleted successfully',
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Create Bill
exports.createBill = async (req, res) => {
  try {
    const {
      propertyId,
      roomId,
      tenantId,
      billDate,
      dueDate,
      charges,
    } = req.body;

    const totalAmount = Object.values(charges).reduce((sum, val) => sum + (parseFloat(val) || 0), 0);

    const bill = await Bill.create({
      property: propertyId,
      room: roomId,
      tenant: tenantId,
      billDate: billDate || new Date(),
      dueDate,
      charges,
      totalAmount,
      paidAmount: 0,
      status: 'pending',
    });

    // Create notification
    const { createBillNotification } = require('../services/notificationService');
    await createBillNotification(tenantId, bill);

    // Send email and WhatsApp notifications
    const tenant = await Tenant.findById(tenantId);
    if (tenant) {
      const { sendBillNotification } = require('../services/emailService');
      const { sendBillNotificationWhatsApp } = require('../services/whatsappService');

      await sendBillNotification(tenant, bill);
      await sendBillNotificationWhatsApp(tenant.phone, bill);
    }

    res.status(201).json({
      success: true,
      bill,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get All Bills
exports.getBills = async (req, res) => {
  try {
    const bills = await Bill.find()
      .populate('property', 'name address')
      .populate('room', 'roomNumber')
      .populate('tenant', 'fullName phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      bills,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get All Payments
exports.getPayments = async (req, res) => {
  try {
    const payments = await Payment.find()
      .populate('bill')
      .populate('tenant', 'fullName phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      payments,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Maintenance Requests
exports.getMaintenanceRequests = async (req, res) => {
  try {
    const requests = await MaintenanceRequest.find()
      .populate('property', 'name address')
      .populate('room', 'roomNumber')
      .populate('tenant', 'fullName phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      requests,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Add Ad
exports.addAd = async (req, res) => {
  try {
    const { link } = req.body;

    const { uploadToCloudinary } = require('../services/cloudinaryService');

    let image = '';
    if (req.file) {
      image = await uploadToCloudinary(req.file.buffer, 'clusternest/ads');
    }

    const ad = await Ad.create({
      image,
      link,
      active: true,
    });

    res.status(201).json({
      success: true,
      ad,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Ads
exports.getAds = async (req, res) => {
  try {
    const ads = await Ad.find({ active: true }).sort({ createdAt: -1 });

    res.json({
      success: true,
      ads,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
