const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    refPath: 'userType',
  },
  userType: {
    type: String,
    enum: ['Tenant', 'Admin'],
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  message: {
    type: String,
    required: true,
    trim: true,
  },
  type: {
    type: String,
    enum: ['bill', 'payment', 'complaint', 'maintenance', 'message', 'announcement', 'other'],
    default: 'other',
  },
  read: {
    type: Boolean,
    default: false,
  },
  link: {
    type: String,
    trim: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Notification', notificationSchema);
