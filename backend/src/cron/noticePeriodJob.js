const cron = require('node-cron');
const VacationNotice = require('../models/VacationNotice');
const Room = require('../models/Room');
const Tenant = require('../models/Tenant');
const { createNotification } = require('../services/notificationService');

// Run daily at midnight
cron.schedule('0 0 * * *', async () => {
  try {
    console.log('Running vacation notice period check...');
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Find all active notices where effective date has passed
    const notices = await VacationNotice.find({
      status: 'active',
      effectiveDate: { $lte: today },
    }).populate('room tenant');

    for (const notice of notices) {
      // Update room status to free
      if (notice.room) {
        notice.room.status = 'free';
        notice.room.currentTenant = null;
        await notice.room.save();
      }

      // Update tenant's current room
      if (notice.tenant) {
        notice.tenant.currentRoom = null;
        notice.tenant.currentProperty = null;
        await notice.tenant.save();
      }

      // Mark notice as processed
      notice.status = 'processed';
      await notice.save();

      // Create notification
      if (notice.tenant) {
        await createNotification(
          notice.tenant._id,
          'Tenant',
          'Room Vacated',
          'Your room has been vacated as per your vacation notice.',
          'other'
        );
      }

      console.log(`Processed vacation notice for tenant ${notice.tenant?._id}`);
    }

    console.log(`Processed ${notices.length} vacation notices`);
  } catch (error) {
    console.error('Error in vacation notice cron job:', error);
  }
});

console.log('Vacation notice period cron job scheduled (runs daily at midnight)');
