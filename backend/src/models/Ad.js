const mongoose = require('mongoose');

const adSchema = new mongoose.Schema({
  image: {
    type: String, // Cloudinary URL
    required: true,
  },
  link: {
    type: String,
    trim: true,
  },
  active: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Ad', adSchema);
