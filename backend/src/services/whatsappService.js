const twilio = require('../config/twilio');

const sendWhatsAppMessage = async (to, message, mediaUrl = null) => {
  try {
    const messageOptions = {
      from: twilio.whatsappNumber,
      to: `whatsapp:${to}`,
      body: message,
    };

    if (mediaUrl) {
      messageOptions.mediaUrl = [mediaUrl];
    }

    const result = await twilio.client.messages.create(messageOptions);
    return { success: true, messageId: result.sid };
  } catch (error) {
    console.error('WhatsApp sending error:', error);
    return { success: false, error: error.message };
  }
};

const sendBillNotificationWhatsApp = async (tenantPhone, bill) => {
  const message = `🏠 *New Bill Generated*\n\nDear ${tenantPhone},\n\nA new bill has been generated.\n\n*Total Amount:* ₹${bill.totalAmount}\n*Due Date:* ${bill.dueDate.toLocaleDateString()}\n\nPlease make the payment before the due date.\n\nThank you,\nClusterNest Team`;

  return await sendWhatsAppMessage(tenantPhone, message);
};

const sendPaymentConfirmationWhatsApp = async (tenantPhone, payment, invoiceUrl) => {
  const message = `✅ *Payment Confirmed*\n\nYour payment of ₹${payment.amount} has been confirmed.\n\nPayment Date: ${payment.paymentDate.toLocaleDateString()}\n\nPlease find the invoice in your email.\n\nThank you,\nClusterNest Team`;

  return await sendWhatsAppMessage(tenantPhone, message, invoiceUrl);
};

module.exports = {
  sendWhatsAppMessage,
  sendBillNotificationWhatsApp,
  sendPaymentConfirmationWhatsApp,
};
