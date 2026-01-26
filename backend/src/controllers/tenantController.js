const Tenant = require('../models/Tenant');
const Property = require('../models/Property');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');
const Complaint = require('../models/Complaint');
const MaintenanceRequest = require('../models/MaintenanceRequest');
const Notification = require('../models/Notification');
const Message = require('../models/Message');
const Request = require('../models/Request');
const VacationNotice = require('../models/VacationNotice');
const Ad = require('../models/Ad');
const Agreement = require('../models/Agreement');

// Get Dashboard Data
exports.getDashboard = async (req, res) => {
  try {
    const tenant = req.tenant;

    // Get ads
    const ads = await Ad.find({ active: true }).sort({ createdAt: -1 });

    // Get pending bills
    const pendingBills = await Bill.find({
      tenant: tenant._id,
      status: { $in: ['pending', 'overdue'] },
    })
      .populate('property', 'name')
      .populate('room', 'roomNumber')
      .sort({ dueDate: 1 })
      .limit(5);

    // Get unread notifications count
    const unreadCount = await Notification.countDocuments({
      user: tenant._id,
      userType: 'Tenant',
      read: false,
    });

    res.json({
      success: true,
      data: {
        ads,
        pendingBills,
        unreadNotifications: unreadCount,
      },
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
          select: 'fullName phone',
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

// Get Tenant Bills
exports.getBills = async (req, res) => {
  try {
    const tenant = req.tenant;

    const bills = await Bill.find({ tenant: tenant._id })
      .populate('property', 'name address')
      .populate('room', 'roomNumber')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      bills,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Bill Details
exports.getBill = async (req, res) => {
  try {
    const { id } = req.params;
    const tenant = req.tenant;

    const bill = await Bill.findOne({ _id: id, tenant: tenant._id })
      .populate('property', 'name address')
      .populate('room', 'roomNumber')
      .populate('tenant', 'fullName phone email');

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    res.json({
      success: true,
      bill,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Initiate Payment
exports.initiatePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const tenant = req.tenant;

    const bill = await Bill.findOne({ _id: id, tenant: tenant._id });
    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    const amountToPay = bill.totalAmount - bill.paidAmount;
    if (amountToPay <= 0) {
      return res.status(400).json({ message: 'Bill already paid' });
    }

    const { createOrder } = require('../services/razorpayService');
    const receipt = `bill_${bill._id}_${Date.now()}`;
    const orderResult = await createOrder(amountToPay, 'INR', receipt);

    if (!orderResult.success) {
      return res.status(500).json({ message: 'Payment initiation failed', error: orderResult.error });
    }

    res.json({
      success: true,
      order: orderResult.order,
      billId: bill._id,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Verify Payment
exports.verifyPayment = async (req, res) => {
  try {
    const { billId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const tenant = req.tenant;

    const { verifyPayment: verifyRazorpayPayment } = require('../services/razorpayService');
    const isValid = verifyRazorpayPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);

    if (!isValid) {
      return res.status(400).json({ message: 'Payment verification failed' });
    }

    const bill = await Bill.findById(billId);
    if (!bill || bill.tenant.toString() !== tenant._id.toString()) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Get payment amount from Razorpay order
    const razorpay = require('../config/razorpay');
    const order = await razorpay.orders.fetch(razorpay_order_id);
    const amount = order.amount / 100; // Convert from paise to rupees

    // Create payment record
    const payment = await Payment.create({
      bill: billId,
      tenant: tenant._id,
      amount,
      paymentDate: new Date(),
      paymentMethod: 'razorpay',
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      razorpaySignature: razorpay_signature,
      status: 'success',
    });

    // Update bill
    bill.paidAmount += amount;
    if (bill.paidAmount >= bill.totalAmount) {
      bill.status = 'paid';
    } else {
      bill.status = 'partial';
    }
    await bill.save();

    // Generate invoice PDF
    const { generateInvoicePDF } = require('../services/pdfService');
    const property = await Property.findById(bill.property);
    const Room = require('../models/Room');
    const room = await Room.findById(bill.room);

    const pdfBuffer = await generateInvoicePDF(bill, tenant, property, room);

    // Upload PDF to Cloudinary
    const { uploadToCloudinary } = require('../services/cloudinaryService');
    const invoiceUrl = await uploadToCloudinary(pdfBuffer, 'clusternest/invoices');

    payment.invoicePdf = invoiceUrl;
    await payment.save();

    // Create notification
    const { createPaymentNotification } = require('../services/notificationService');
    await createPaymentNotification(tenant._id, payment);

    // Send email and WhatsApp
    const { sendPaymentConfirmation } = require('../services/emailService');
    const { sendPaymentConfirmationWhatsApp } = require('../services/whatsappService');

    await sendPaymentConfirmation(tenant, payment, invoiceUrl);
    await sendPaymentConfirmationWhatsApp(tenant.phone, payment, invoiceUrl);

    res.json({
      success: true,
      payment,
      invoiceUrl,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Payment History
exports.getPayments = async (req, res) => {
  try {
    const tenant = req.tenant;

    const payments = await Payment.find({ tenant: tenant._id })
      .populate('bill')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      payments,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Download Invoice
exports.downloadInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    const tenant = req.tenant;

    const payment = await Payment.findOne({ _id: id, tenant: tenant._id });
    if (!payment || !payment.invoicePdf) {
      return res.status(404).json({ message: 'Invoice not found' });
    }

    res.json({
      success: true,
      invoiceUrl: payment.invoicePdf,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Raise Complaint
exports.raiseComplaint = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { title, description, category } = req.body;

    const complaint = await Complaint.create({
      tenant: tenant._id,
      property: tenant.currentProperty,
      title,
      description,
      category,
      status: 'open',
    });

    res.status(201).json({
      success: true,
      complaint,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Complaints
exports.getComplaints = async (req, res) => {
  try {
    const tenant = req.tenant;

    const complaints = await Complaint.find({ tenant: tenant._id })
      .populate('property', 'name address')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      complaints,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Create Maintenance Request
exports.createMaintenanceRequest = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { description, priority } = req.body;

    const request = await MaintenanceRequest.create({
      tenant: tenant._id,
      property: tenant.currentProperty,
      room: tenant.currentRoom,
      description,
      priority: priority || 'medium',
      status: 'pending',
    });

    res.status(201).json({
      success: true,
      request,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Maintenance Requests
exports.getMaintenanceRequests = async (req, res) => {
  try {
    const tenant = req.tenant;

    const requests = await MaintenanceRequest.find({ tenant: tenant._id })
      .populate('property', 'name address')
      .populate('room', 'roomNumber')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      requests,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Guest Visit Request
exports.guestVisitRequest = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { title, description, requestDate } = req.body;

    const request = await Request.create({
      tenant: tenant._id,
      property: tenant.currentProperty,
      requestType: 'guest-visit',
      title,
      description,
      requestDate,
      status: 'pending',
    });

    res.status(201).json({
      success: true,
      request,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Parking Request
exports.parkingRequest = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { title, description, requestDate } = req.body;

    const request = await Request.create({
      tenant: tenant._id,
      property: tenant.currentProperty,
      requestType: 'parking',
      title,
      description,
      requestDate,
      status: 'pending',
    });

    res.status(201).json({
      success: true,
      request,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Vacation Notice
exports.vacationNotice = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { reason } = req.body;

    if (!tenant.currentRoom) {
      return res.status(400).json({ message: 'No room assigned' });
    }

    const noticeDate = new Date();
    const effectiveDate = new Date(noticeDate);
    effectiveDate.setMonth(effectiveDate.getMonth() + 1);

    const notice = await VacationNotice.create({
      tenant: tenant._id,
      property: tenant.currentProperty,
      room: tenant.currentRoom,
      noticeDate,
      effectiveDate,
      reason,
      status: 'active',
    });

    res.status(201).json({
      success: true,
      notice,
      message: 'Vacation notice submitted. Room will be freed after 1 month.',
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Notifications
exports.getNotifications = async (req, res) => {
  try {
    const tenant = req.tenant;

    const notifications = await Notification.find({
      user: tenant._id,
      userType: 'Tenant',
    })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({
      success: true,
      notifications,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Mark Notification as Read
exports.markNotificationRead = async (req, res) => {
  try {
    const { id } = req.params;
    const tenant = req.tenant;

    const notification = await Notification.findOne({
      _id: id,
      user: tenant._id,
      userType: 'Tenant',
    });

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    notification.read = true;
    await notification.save();

    res.json({
      success: true,
      notification,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Messages
exports.getMessages = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { receiverId } = req.query;

    // Get messages where tenant is sender or receiver
    const messages = await Message.find({
      $or: [
        { sender: tenant._id, senderType: 'Tenant' },
        { receiver: tenant._id, receiverType: 'Tenant' },
      ],
    })
      .sort({ createdAt: 1 });

    res.json({
      success: true,
      messages,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Send Message
exports.sendMessage = async (req, res) => {
  try {
    const tenant = req.tenant;
    const { receiverId, receiverType, message } = req.body;

    const newMessage = await Message.create({
      sender: tenant._id,
      senderType: 'Tenant',
      receiver: receiverId,
      receiverType: receiverType || 'Admin',
      message,
      read: false,
    });

    res.status(201).json({
      success: true,
      message: newMessage,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Profile
exports.getProfile = async (req, res) => {
  try {
    const tenant = req.tenant;

    const profile = await Tenant.findById(tenant._id)
      .select('-password -otp -otpExpiry')
      .populate('currentProperty', 'name address')
      .populate('currentRoom', 'roomNumber');

    // Get agreement
    const agreement = await Agreement.findOne({
      tenant: tenant._id,
      status: 'active',
    })
      .populate('property', 'name address')
      .populate('room', 'roomNumber');

    res.json({
      success: true,
      profile,
      agreement,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update Profile
exports.updateProfile = async (req, res) => {
  try {
    const tenant = req.tenant;
    const updateData = req.body;

    // Handle profile photo upload
    if (req.file) {
      const { uploadToCloudinary } = require('../services/cloudinaryService');
      updateData.profilePhoto = await uploadToCloudinary(req.file.buffer, 'clusternest/profiles');
    }

    const updatedTenant = await Tenant.findByIdAndUpdate(
      tenant._id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password -otp -otpExpiry');

    res.json({
      success: true,
      tenant: updatedTenant,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
