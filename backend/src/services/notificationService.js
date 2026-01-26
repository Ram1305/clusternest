const Notification = require('../models/Notification');

const createNotification = async (userId, userType, title, message, type = 'other', link = null) => {
  try {
    const notification = await Notification.create({
      user: userId,
      userType,
      title,
      message,
      type,
      link,
    });
    return notification;
  } catch (error) {
    console.error('Notification creation error:', error);
    return null;
  }
};

const createBillNotification = async (tenantId, bill) => {
  return await createNotification(
    tenantId,
    'Tenant',
    'New Bill Generated',
    `A new bill of ₹${bill.totalAmount} has been generated. Due date: ${bill.dueDate.toLocaleDateString()}`,
    'bill',
    `/bills/${bill._id}`
  );
};

const createPaymentNotification = async (tenantId, payment) => {
  return await createNotification(
    tenantId,
    'Tenant',
    'Payment Confirmed',
    `Your payment of ₹${payment.amount} has been confirmed.`,
    'payment',
    `/payments/${payment._id}`
  );
};

module.exports = {
  createNotification,
  createBillNotification,
  createPaymentNotification,
};
