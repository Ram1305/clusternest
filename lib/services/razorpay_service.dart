import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class RazorpayService {
  static final Razorpay _razorpay = Razorpay();
  static String? _razorpayKeyId;

  // Initialize Razorpay with key ID
  static void initialize(String keyId) {
    _razorpayKeyId = keyId;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Get Razorpay key ID from backend (you may want to add an endpoint for this)
  // For now, this should be set manually or fetched from config
  static Future<String?> getRazorpayKeyId() async {
    // TODO: Add endpoint to get Razorpay key ID from backend
    // For now, return null - key should be set via initialize()
    return _razorpayKeyId;
  }

  // Open Razorpay checkout
  static Future<void> openCheckout({
    required String orderId,
    required String keyId,
    required String name,
    required String description,
    required double amount,
    required String prefillContact,
    required String prefillEmail,
    Function(Map<String, dynamic>)? onSuccess,
    Function(String)? onError,
  }) async {
    _onSuccessCallback = onSuccess;
    _onErrorCallback = onError;

    final options = {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': prefillContact,
        'email': prefillEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  static Function(Map<String, dynamic>)? _onSuccessCallback;
  static Function(String)? _onErrorCallback;

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccessCallback?.call({
      'razorpay_payment_id': response.paymentId,
      'razorpay_order_id': response.orderId,
      'razorpay_signature': response.signature,
    });
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    _onErrorCallback?.call(response.message ?? 'Payment failed');
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet selection
    _onErrorCallback?.call('External wallet selected: ${response.walletName}');
  }

  // Cleanup
  static void dispose() {
    _razorpay.clear();
  }
}
