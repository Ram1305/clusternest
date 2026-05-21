const mongoose = require('mongoose');
const Admin = require('../models/Admin');
const { requireEnv } = require('../config/env');

const createAdmin = async () => {
  try {
    await mongoose.connect(requireEnv('MONGODB_URI'));
    console.log('MongoDB Connected');

    // Check if admin already exists
    const existingAdmin = await Admin.findOne({ email: 'admin@gmail.com' });
    if (existingAdmin) {
      console.log('Admin already exists');
      process.exit(0);
    }

    // Create default admin
    const admin = await Admin.create({
      email: 'admin@gmail.com',
      password: '123456',
      name: 'Admin User',
    });

    console.log('Admin created successfully:', admin.email);
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
};

createAdmin();
