const mongoose = require('mongoose');

const vacationNoticeSchema = new mongoose.Schema({
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
  noticeDate: {
    type: Date,
    required: true,
    default: Date.now,
  },
  effectiveDate: {
    type: Date,
    required: true,
  },
  reason: {
    type: String,
    trim: true,
  },
  status: {
    type: String,
    enum: ['active', 'processed'],
    default: 'active',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('VacationNotice', vacationNoticeSchema);
