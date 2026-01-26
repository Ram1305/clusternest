const Tenant = require('../models/Tenant');
const auth = require('./auth');

const tenantAuth = async (req, res, next) => {
  try {
    await auth(req, res, async () => {
      if (req.user.userType !== 'tenant') {
        return res.status(403).json({ message: 'Access denied. Tenant only.' });
      }
      const tenant = await Tenant.findById(req.user.id);
      if (!tenant) {
        return res.status(404).json({ message: 'Tenant not found' });
      }
      req.tenant = tenant;
      next();
    });
  } catch (error) {
    res.status(401).json({ message: 'Authentication failed' });
  }
};

module.exports = tenantAuth;
