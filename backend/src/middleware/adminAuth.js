const Admin = require('../models/Admin');
const auth = require('./auth');

const adminAuth = async (req, res, next) => {
  try {
    await auth(req, res, async () => {
      if (req.user.userType !== 'admin') {
        return res.status(403).json({ message: 'Access denied. Admin only.' });
      }
      const admin = await Admin.findById(req.user.id);
      if (!admin) {
        return res.status(404).json({ message: 'Admin not found' });
      }
      req.admin = admin;
      next();
    });
  } catch (error) {
    res.status(401).json({ message: 'Authentication failed' });
  }
};

module.exports = adminAuth;
