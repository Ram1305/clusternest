const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

const generateInvoicePDF = async (bill, tenant, property, room) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });
      const chunks = [];
      
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Header
      doc.fontSize(20).text('ClusterNest', { align: 'center' });
      doc.fontSize(16).text('Invoice', { align: 'center' });
      doc.moveDown();

      // Bill Details
      doc.fontSize(12);
      doc.text(`Bill Number: ${bill._id}`, { align: 'left' });
      doc.text(`Bill Date: ${bill.billDate.toLocaleDateString()}`, { align: 'left' });
      doc.text(`Due Date: ${bill.dueDate.toLocaleDateString()}`, { align: 'left' });
      doc.moveDown();

      // Tenant Details
      doc.text('Tenant Details:', { underline: true });
      doc.text(`Name: ${tenant.fullName}`);
      doc.text(`Phone: ${tenant.phone}`);
      if (tenant.email) doc.text(`Email: ${tenant.email}`);
      doc.moveDown();

      // Property Details
      doc.text('Property Details:', { underline: true });
      doc.text(`Property: ${property.name}`);
      doc.text(`Address: ${property.address}`);
      doc.text(`Room: ${room.roomNumber}`);
      doc.moveDown();

      // Charges Breakdown
      doc.text('Charges Breakdown:', { underline: true });
      doc.moveDown(0.5);
      
      const charges = [
        { label: 'Basic Rent', amount: bill.charges.basicRent },
        { label: 'EB Bill', amount: bill.charges.ebBill },
        { label: 'Internet Payment', amount: bill.charges.internetPayment },
        { label: 'Maintenance Charge', amount: bill.charges.maintenanceCharge },
        { label: 'Food Charge', amount: bill.charges.foodCharge },
        { label: 'Fine Charges', amount: bill.charges.fineCharges },
        { label: 'Other Charges', amount: bill.charges.otherCharges },
      ];

      charges.forEach(charge => {
        if (charge.amount > 0) {
          doc.text(`${charge.label}: ₹${charge.amount}`, { indent: 20 });
        }
      });

      doc.moveDown();
      doc.fontSize(14).text(`Total Amount: ₹${bill.totalAmount}`, { align: 'right', underline: true });
      doc.moveDown();
      doc.fontSize(10).text(`Paid Amount: ₹${bill.paidAmount}`, { align: 'right' });
      doc.fontSize(10).text(`Balance: ₹${bill.totalAmount - bill.paidAmount}`, { align: 'right' });

      // Footer
      doc.moveDown(2);
      doc.fontSize(10).text('Thank you for your payment!', { align: 'center' });
      doc.text('ClusterNest - Your Home, Your Nest', { align: 'center' });

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
};

module.exports = {
  generateInvoicePDF,
};
