const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  property: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Property',
    required: true,
  },
  roomNumber: {
    type: String,
    required: true,
    trim: true,
  },
  status: {
    type: String,
    enum: ['available', 'occupied', 'free'],
    default: 'available',
  },
  currentTenant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
  },
  agreementStartDate: {
    type: Date,
  },
  agreementEndDate: {
    type: Date,
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
  agreementDocument: {
    type: String, // Cloudinary URL
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Room', roomSchema);
