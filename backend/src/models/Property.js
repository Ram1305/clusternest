const mongoose = require('mongoose');

const propertySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  address: {
    type: String,
    required: true,
    trim: true,
  },
  latitude: {
    type: Number,
    required: true,
  },
  longitude: {
    type: Number,
    required: true,
  },
  bhkType: {
    type: String,
    enum: ['RK', '1BHK', '2BHK', '3BHK', '4BHK'],
    required: true,
  },
  mainImage: {
    type: String, // Cloudinary URL
    required: true,
  },
  images: [{
    type: String, // Cloudinary URLs
  }],
  amenities: [{
    type: String,
    trim: true,
  }],
  genderPreference: {
    type: String,
    enum: ['male', 'female', 'both'],
    default: 'both',
  },
  rooms: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
  }],
  isActive: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Property', propertySchema);
