const twilio = require('twilio');

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

module.exports = {
  client: twilioClient,
  whatsappNumber: process.env.TWILIO_WHATSAPP_NUMBER,
};
