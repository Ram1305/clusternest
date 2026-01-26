const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const sendEmail = async (to, subject, text, html, attachments = []) => {
  try {
    const mailOptions = {
      from: `"ClusterNest" <${process.env.SMTP_USER}>`,
      to,
      subject,
      text,
      html,
      attachments,
    };

    const info = await transporter.sendMail(mailOptions);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Email sending error:', error);
    return { success: false, error: error.message };
  }
};

const sendBillNotification = async (tenant, bill) => {
  const subject = `New Bill Generated - ${bill.billDate.toLocaleDateString()}`;
  const html = `
    <h2>New Bill Generated</h2>
    <p>Dear ${tenant.fullName},</p>
    <p>A new bill has been generated for your room.</p>
    <p><strong>Total Amount:</strong> ₹${bill.totalAmount}</p>
    <p><strong>Due Date:</strong> ${bill.dueDate.toLocaleDateString()}</p>
    <p>Please make the payment before the due date.</p>
    <p>Thank you,<br>ClusterNest Team</p>
  `;
  const text = `New bill generated. Total: ₹${bill.totalAmount}, Due: ${bill.dueDate.toLocaleDateString()}`;

  return await sendEmail(tenant.email || tenant.phone + '@example.com', subject, text, html);
};

const sendPaymentConfirmation = async (tenant, payment, invoiceUrl) => {
  const subject = `Payment Confirmed - ₹${payment.amount}`;
  const html = `
    <h2>Payment Confirmed</h2>
    <p>Dear ${tenant.fullName},</p>
    <p>Your payment of ₹${payment.amount} has been confirmed.</p>
    <p>Payment Date: ${payment.paymentDate.toLocaleDateString()}</p>
    <p>Please find the invoice attached.</p>
    <p>Thank you,<br>ClusterNest Team</p>
  `;
  const text = `Payment confirmed: ₹${payment.amount}`;

  const attachments = invoiceUrl ? [{ path: invoiceUrl }] : [];

  return await sendEmail(tenant.email || tenant.phone + '@example.com', subject, text, html, attachments);
};

module.exports = {
  sendEmail,
  sendBillNotification,
  sendPaymentConfirmation,
};
