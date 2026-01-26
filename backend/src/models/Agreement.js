const mongoose = require('mongoose');

const agreementSchema = new mongoose.Schema({
  tenant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
  },
  property: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Property',
    required: true,
  },
  room: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
  },
  startDate: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
    required: true,
  },
  monthlyRent: {
    type: Number,
    required: true,
  },
  securityDeposit: {
    type: Number,
    required: true,
  },
  maintenanceAmount: {
    type: Number,
    default: 0,
  },
  document: {
    type: String, // Cloudinary URL
  },
  status: {
    type: String,
    enum: ['active', 'terminated', 'expired'],
    default: 'active',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Agreement', agreementSchema);
