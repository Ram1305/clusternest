# ClusterNest Setup Guide

## Quick Start

### 1. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your credentials
npm run create-admin  # Creates default admin (admin@gmail.com / 123456)
npm run dev
```

### 2. Frontend Setup

```bash
cd frontend
flutter pub get
# Add Poppins font files to fonts/ directory
# Update API base URL in lib/config/api_config.dart
flutter run
```

### 3. Initial Setup Checklist

- [ ] MongoDB running
- [ ] Backend .env configured
- [ ] Admin user created (`npm run create-admin`)
- [ ] Backend server running on port 3000
- [ ] Frontend API URL configured
- [ ] Poppins fonts added
- [ ] Cloudinary account configured
- [ ] Twilio account configured (for WhatsApp)
- [ ] Razorpay account configured (for payments)
- [ ] Email SMTP configured

## Default Credentials

**Admin:**
- Email: admin@gmail.com
- Password: 123456

## API Base URL Configuration

For Flutter app, update `lib/config/api_config.dart`:

- **Android Emulator**: `http://10.0.2.2:3000/api`
- **iOS Simulator**: `http://localhost:3000/api`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3000/api`

## Font Setup

The app uses [Google Fonts](https://fonts.google.com/specimen/Poppins) (Poppins) via the `google_fonts` package. No manual font setup is required—fonts are fetched at runtime.

## Testing the Application

1. **Admin Login**: Double-tap splash screen → Login with admin credentials
2. **Tenant Registration**: Sign up as new tenant (multi-step form)
3. **Approve Tenant**: Admin dashboard → Approve Tenant
4. **Add Property**: Admin dashboard → Add Property
5. **Create Bill**: Admin dashboard → Add Bill
6. **Make Payment**: Tenant dashboard → Pay bill
7. **Check Notifications**: Verify email, WhatsApp, and in-app notifications

## Troubleshooting

### Backend Issues
- Ensure MongoDB is running
- Check .env file has all required variables
- Verify port 3000 is not in use
- Check console for error messages

### Frontend Issues
- Ensure backend is running
- Verify API base URL is correct
- Check network permissions for physical devices
- Verify all dependencies installed (`flutter pub get`)

### Image Upload Issues
- Verify Cloudinary credentials in .env
- Check file size limits (10MB max)
- Ensure proper image format (jpeg, jpg, png, gif)

### Payment Issues
- Verify Razorpay credentials
- Check test mode vs production mode
- Verify webhook URLs if using webhooks

## Production Deployment

### Backend
- Use PM2 or similar process manager
- Enable HTTPS
- Set proper CORS origins
- Use environment-specific .env files
- Enable MongoDB authentication
- Use strong JWT secret

### Frontend
- Build release APK/IPA
- Update API URLs to production
- Enable code obfuscation
- Configure app signing
- Update app version in pubspec.yaml

## Support

For issues or questions, refer to the main README.md file.
