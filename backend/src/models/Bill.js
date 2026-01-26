const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
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
  tenant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
  },
  billDate: {
    type: Date,
    required: true,
    default: Date.now,
  },
  dueDate: {
    type: Date,
    required: true,
  },
  charges: {
    basicRent: { type: Number, default: 0 },
    ebBill: { type: Number, default: 0 },
    internetPayment: { type: Number, default: 0 },
    maintenanceCharge: { type: Number, default: 0 },
    foodCharge: { type: Number, default: 0 },
    fineCharges: { type: Number, default: 0 },
    otherCharges: { type: Number, default: 0 },
  },
  totalAmount: {
    type: Number,
    required: true,
  },
  paidAmount: {
    type: Number,
    default: 0,
  },
  status: {
    type: String,
    enum: ['pending', 'paid', 'overdue', 'partial'],
    default: 'pending',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Bill', billSchema);
