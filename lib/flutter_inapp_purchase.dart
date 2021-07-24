import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'modules.dart';
import 'utils.dart';

export 'modules.dart';

/// A enumeration of in-app purchase types for Android
/// https://developer.android.com/reference/com/android/billingclient/api/BillingClient.SkuType.html#constants_2
enum _TypeInApp { inapp, subs }

class FlutterInappPurchase {
  static FlutterInappPurchase instance =
      FlutterInappPurchase(FlutterInappPurchase.private(const LocalPlatform()));

  static StreamController<PurchasedItem>? _purchaseController;
  static Stream<PurchasedItem> get purchaseUpdated =>
      _purchaseController!.stream;

  static StreamController<PurchaseResult>? _purchaseErrorController;
  static Stream<PurchaseResult> get purchaseError =>
      _purchaseErrorController!.stream;

  static StreamController<ConnectionResult>? _connectionController;
  static Stream<ConnectionResult> get connectionUpdated =>
      _connectionController!.stream;

  static StreamController<String>? _purchasePromotedController;
  static Stream<String> get purchasePromoted =>
      _purchasePromotedController!.stream;

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  static final MethodChannel _channel = const MethodChannel('flutter_inapp');
  static MethodChannel get channel => _channel;

  final Platform _pf;
  final http.Client? _httpClient;

  static Platform get _platform => instance._pf;
  static http.Client? get _client => instance._httpClient;

  factory FlutterInappPurchase(FlutterInappPurchase _instance) {
    instance = _instance;
    return instance;
  }

  PlatformException get _platformException => PlatformException(
        code: _platform.operatingSystem,
        message: "platform not supported",
      );

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform, {http.Client? client})
      : _pf = platform,
        _httpClient = client;

  /// Returns the platform version on `Android` and `iOS`.
  ///
  /// eg, `Android 5.1.1`
  Future<String?> get platformVersion async {
    return _channel.invokeMethod<String>('getPlatformVersion');
  }

  /// Consumes all items on `Android`.
  ///
  /// Particularly useful for removing all consumable items.
  Future get consumeAllItemsAndroid async {
    if (_platform.isAndroid) {
      final String? result = await _channel.invokeMethod('consumeAllItems');
      return result;
    }

    throw _platformException;
  }

  /// InitConnection prepare iap features for both `Android` and `iOS`.
  ///
  /// This must be called on `Android` and `iOS` before purchasing.
  /// On `iOS`, it also checks if the client can make payments.
  Future<String?> get initConnection async {
    if (_platform.isAndroid) {
      await _setPurchaseListener();
      return _channel.invokeMethod<String>('initConnection');
    } else if (_platform.isIOS) {
      await _setPurchaseListener();
      return _channel.invokeMethod<String>('canMakePayments');
    }

    throw _platformException;
  }

  /// Retrieves a list of products from the store on `Android` and `iOS`.
  ///
  /// `iOS` also returns subscriptions.
  Future<List<IAPItem>> getProducts(List<String> skus) async {
    if (skus.isEmpty) return [];
    if (_platform.isAndroid) {
      final result = await _channel.invokeListMethod<Map>(
        'getItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.inapp),
          'skus': skus,
        },
      );
      return extractItems(result ?? []);
    } else if (_platform.isIOS) {
      final result = await _channel.invokeListMethod(
        'getItems',
        {'skus': skus},
      );
      return extractItems(result ?? []);
    }

    throw _platformException;
  }

  /// Retrieves subscriptions on `Android` and `iOS`.
  ///
  /// `iOS` also returns non-subscription products.
  Future<List<IAPItem>> getSubscriptions(List<String> skus) async {
    if (skus.isEmpty) return [];
    if (_platform.isAndroid) {
      final result = await _channel.invokeListMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.subs),
          'skus': skus,
        },
      );

      return extractItems(result ?? []);
    } else if (_platform.isIOS) {
      final result = await _channel.invokeListMethod(
        'getItems',
        {'skus': skus},
      );

      return extractItems(result ?? []);
    }

    throw _platformException;
  }

  /// Retrieves the user's purchase history on `Android` and `iOS` regardless of consumption status.
  ///
  /// Purchase history includes all types of products.
  /// Identical to [getAvailablePurchases] on `iOS`.
  Future<List<PurchasedItem>> getPurchaseHistory() async {
    if (_platform.isAndroid) {
      final getInappPurchaseHistory = _channel.invokeListMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{'type': EnumUtil.getValueString(_TypeInApp.inapp)},
      );

      final getSubsPurchaseHistory = _channel.invokeListMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{'type': EnumUtil.getValueString(_TypeInApp.subs)},
      );

      final results =
          await Future.wait([getInappPurchaseHistory, getSubsPurchaseHistory]);

      return extractPurchased((results[0] ?? []) + (results[1] ?? []));
    } else if (_platform.isIOS) {
      final result = await _channel.invokeListMethod('getAvailableItems');

      return extractPurchased(result ?? []);
    }

    throw _platformException;
  }

  /// Get all non-consumed purchases made on `Android` and `iOS`.
  ///
  /// This is identical to [getPurchaseHistory] on `iOS`
  Future<List<PurchasedItem>> getAvailablePurchases() async {
    if (_platform.isAndroid) {
      final getInAppAvailable = _channel.invokeListMethod(
        'getAvailableItemsByType',
        <String, dynamic>{'type': EnumUtil.getValueString(_TypeInApp.inapp)},
      );

      final getSubsAvailable = _channel.invokeListMethod(
        'getAvailableItemsByType',
        <String, dynamic>{'type': EnumUtil.getValueString(_TypeInApp.subs)},
      );

      final results = await Future.wait([getInAppAvailable, getSubsAvailable]);

      return extractPurchased((results[0] ?? []) + (results[1] ?? []));
    } else if (_platform.isIOS) {
      final result = await _channel.invokeListMethod('getAvailableItems');

      return extractPurchased(result ?? []);
    }

    throw _platformException;
  }

  /// Request a purchase on `Android` or `iOS`.
  /// Result will be received in `purchaseUpdated` listener or `purchaseError` listener.
  ///
  /// Check [AndroidProrationMode] for valid proration values
  /// Identical to [requestSubscription] on `iOS`.
  Future requestPurchase(
    String sku, {
    String? obfuscatedAccountId,
    String? purchaseTokenAndroid,
    String? obfuscatedProfileIdAndroid,
  }) async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': EnumUtil.getValueString(_TypeInApp.inapp),
        'sku': sku,
        'oldSku': null,
        'prorationMode': -1,
        'obfuscatedAccountId': obfuscatedAccountId,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
      });
    } else if (_platform.isIOS) {
      return _channel.invokeMethod('buyProduct', <String, dynamic>{
        'sku': sku,
        'forUser': obfuscatedAccountId,
      });
    }

    throw _platformException;
  }

  /// Request a subscription on `Android` or `iOS`.
  /// Result will be received in `purchaseUpdated` listener or `purchaseError` listener.
  ///
  /// **NOTICE** second parameter is required on `Android`.
  ///
  /// Check [AndroidProrationMode] for valid proration values
  /// Identical to [requestPurchase] on `iOS`.
  Future requestSubscription(
    String sku, {
    String? oldSkuAndroid,
    int? prorationModeAndroid,
    String? obfuscatedAccountId,
    String? obfuscatedProfileIdAndroid,
    String? purchaseTokenAndroid,
  }) async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': EnumUtil.getValueString(_TypeInApp.subs),
        'sku': sku,
        'oldSku': oldSkuAndroid,
        'prorationMode': prorationModeAndroid ?? -1,
        'obfuscatedAccountId': obfuscatedAccountId,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
      });
    } else if (_platform.isIOS) {
      return _channel.invokeMethod('buyProduct', <String, dynamic>{
        'sku': sku,
        'forUser': obfuscatedAccountId,
      });
    }

    throw _platformException;
  }

  /// Add Store Payment (iOS only)
  /// Indicates that the App Store purchase should continue from the app instead of the App Store.
  ///
  /// @returns {Future<String>}
  Future<String?> getPromotedProductIOS() async {
    if (_platform.isIOS) {
      return _channel.invokeMethod<String>('getPromotedProduct');
    }

    throw _platformException;
  }

  /// Add Store Payment (iOS only)
  /// Indicates that the App Store purchase should continue from the app instead of the App Store.
  ///
  /// @returns {Future} will receive result from `purchasePromoted` listener.
  Future requestPromotedProductIOS() async {
    if (_platform.isIOS) {
      return _channel.invokeMethod('requestPromotedProduct');
    }

    throw _platformException;
  }

  /// Buy product with offer
  ///
  /// @returns {Future} will receive result from `purchaseUpdated` listener.
  Future requestProductWithOfferIOS(
    String sku,
    String forUser,
    Map<String, dynamic> withOffer,
  ) async {
    if (_platform.isIOS) {
      return _channel.invokeMethod(
        'requestProductWithOfferIOS',
        <String, dynamic>{
          'sku': sku,
          'forUser': forUser,
          'withOffer': withOffer,
        },
      );
    }

    throw _platformException;
  }

  /// Buy product with quantity
  ///
  /// @returns {Future} will receive result from `purchaseUpdated` listener.
  Future requestPurchaseWithQuantityIOS(
    String sku,
    int quantity,
  ) async {
    if (_platform.isIOS) {
      return _channel.invokeMethod(
        'requestPurchaseWithQuantity',
        <String, dynamic>{'sku': sku, 'quantity': quantity},
      );
    }

    throw _platformException;
  }

  /// Get the pending purchases in IOS.
  ///
  /// @returns {Future<List<PurchasedItem>>}
  Future<List<PurchasedItem>> getPendingTransactionsIOS() async {
    if (_platform.isIOS) {
      final result = await _channel.invokeListMethod('getPendingTransactions');
      return extractPurchased(result ?? []);
    }

    throw _platformException;
  }

  /// Acknowledge a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose iap purchases are consumed at the time of purchase.
  Future<String?> acknowledgePurchaseAndroid(String token) async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>(
          'acknowledgePurchase', <String, dynamic>{'token': token});
    }

    throw _platformException;
  }

  /// Consumes a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose consumable purchases are consumed at the time of purchase.
  ///
  /// if you already invoked [getProducts],you ought to invoked this method to confirm you have consumed.
  /// that means you can purchase one IAPItem more times, otherwise you'll receive error code : 7
  ///
  /// in DoobooUtils.java error like this:
  /// case BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
  ///        errorData[0] = E_ALREADY_OWNED;
  ///        errorData[1] = "You already own this item.";
  ///        break;
  Future<String?> consumePurchaseAndroid(String token) async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>('consumeProduct', <String, dynamic>{
        'token': token,
      });
    }

    throw _platformException;
  }

  /// End Play Store connection on `Android` and remove iap observer in `iOS`.
  ///
  /// Absolutely necessary to call this when done with the payment.
  Future<String?> get endConnection async {
    if (_platform.isAndroid || _platform.isIOS) {
      final result = await _channel.invokeMethod<String>('endConnection');
      _removePurchaseListeners();
      return result;
    }

    throw _platformException;
  }

  /// Finish a transaction on `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  Future<String?> finishTransactionIOS(String transactionId) async {
    if (_platform.isIOS) {
      return _channel.invokeMethod<String>(
        'finishTransaction',
        <String, dynamic>{'transactionIdentifier': transactionId},
      );
    }

    throw _platformException;
  }

  /// Finish a transaction on both `android` and `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  Future<PurchaseResult> finishTransaction(PurchasedItem purchasedItem,
      {bool isConsumable = false}) async {
    if (_platform.isAndroid) {
      if (isConsumable) {
        final result = await _channel.invokeMapMethod(
          'consumeProduct',
          <String, dynamic>{'token': purchasedItem.purchaseToken},
        );
        return PurchaseResult.fromJSON(Map<String, dynamic>.from(result ?? {}));
      } else {
        final result = await _channel.invokeMapMethod(
          'acknowledgePurchase',
          <String, dynamic>{'token': purchasedItem.purchaseToken},
        );
        return PurchaseResult.fromJSON(Map<String, dynamic>.from(result ?? {}));
      }
    } else if (_platform.isIOS) {
      final result = await _channel.invokeMapMethod(
        'finishTransaction',
        <String, dynamic>{'transactionIdentifier': purchasedItem.transactionId},
      );
      return PurchaseResult.fromJSON(Map<String, dynamic>.from(result ?? {}));
    }

    throw _platformException;
  }

  /// Clear all remaining transaction on `iOS`.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  Future<String?> clearTransactionIOS() async {
    if (_platform.isIOS) {
      return _channel.invokeMethod<String>('clearTransaction');
    }

    throw _platformException;
  }

  /// Retrieves a list of products that have been attempted to purchase through the App Store `iOS` only.
  ///
  Future<List<IAPItem>> getAppStoreInitiatedProducts() async {
    if (_platform.isIOS) {
      final result =
          await _channel.invokeListMethod('getAppStoreInitiatedProducts');

      return extractItems(result ?? []);
    }

    throw _platformException;
  }

  /// Check if a subscription is active on `Android` and `iOS`.
  ///
  /// This is a quick and dirty way to check if a subscription is active.
  /// It is highly recommended to do server-side validation for all subscriptions.
  /// This method is NOT secure and untested in production.
  Future<bool> checkSubscribed({
    required String sku,
    Duration duration = const Duration(days: 30),
    Duration grace = const Duration(days: 3),
  }) async {
    if (_platform.isIOS) {
      final history = await getPurchaseHistory();

      for (final purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (_platform.isAndroid) {
      var purchases = await getAvailablePurchases();

      for (final purchase in purchases) {
        if (purchase.productId == sku) return true;
      }

      return false;
    }

    throw _platformException;
  }

  /// Validate receipt in ios
  ///
  /// Example:
  /// ```
  /// const receiptBody = {
  /// 'receipt-data': purchased.transactionReceipt,
  /// 'password': '******'
  /// };
  /// const result = await validateReceiptIos(receiptBody, false);
  /// console.log(result);
  /// ```
  Future<http.Response> validateReceiptIos({
    required Map<String, String> receiptBody,
    bool isTest = true,
  }) async {
    final String url =
        'https://${isTest ? 'sandbox' : 'buy'}.itunes.apple.com/verifyReceipt';
    return await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(receiptBody),
    );
  }

  /// Validate receipt in android
  ///
  /// For Android, you need separate json file from the service account to get the access_token from google-apis, therefore it is impossible to implement serverless. You should have your own backend and get access_token.
  /// Read: https://stackoverflow.com/questions/35127086/android-inapp-purchase-receipt-validation-google-play?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
  ///
  /// Example:
  /// ```
  /// const result = await validateReceiptAndroid(
  ///   packageName: 'com.dooboolab.iap',
  ///   productId: 'product_1',
  ///   productToken: 'some_token_string',
  ///   accessToken: 'play_console_access_token',
  ///   isSubscription: false,
  /// );
  /// console.log(result);
  /// ```
  Future<http.Response> validateReceiptAndroid({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    bool isSubscription = false,
  }) async {
    final String type = isSubscription ? 'subscriptions' : 'products';
    final String url =
        'https://www.googleapis.com/androidpublisher/v3/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken';
    return await _client!.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );
  }

  Future _setPurchaseListener() async {
    _purchaseController ??= StreamController.broadcast();
    _connectionController ??= StreamController.broadcast();
    _purchaseErrorController ??= StreamController.broadcast();
    _purchasePromotedController ??= StreamController.broadcast();

    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "purchase-updated":
          final result = Map<String, dynamic>.from(call.arguments ?? {});
          _purchaseController!.add(PurchasedItem.fromJSON(result));
          break;
        case "purchase-error":
          final result = Map<String, dynamic>.from(call.arguments ?? {});
          _purchaseErrorController!.add(PurchaseResult.fromJSON(result));
          break;
        case "connection-updated":
          final result = Map<String, dynamic>.from(call.arguments ?? {});
          _connectionController!.add(ConnectionResult.fromJSON(result));
          break;
        case "iap-promoted-product":
          String? productId = call.arguments;
          if (productId != null && productId.isNotEmpty) {
            _purchasePromotedController!.add(productId);
          }
          break;
        default:
          throw ArgumentError('Unknown method ${call.method}');
      }
    });
  }

  Future _removePurchaseListeners() async {
    _purchaseController?.close();
    _connectionController?.close();
    _purchaseErrorController?.close();
    _purchasePromotedController?.close();
    _purchaseController = null;
    _connectionController = null;
    _purchaseErrorController = null;
    _purchasePromotedController = null;
  }
}

/// A list of valid values for ProrationMode parameter
/// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode
class AndroidProrationMode {
  /// Replacement takes effect when the old plan expires, and the new price will be charged at the same time.
  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#DEFERRED
  static const int DEFERRED = 4;

  /// Replacement takes effect immediately, and the billing cycle remains the same. The price for the remaining period will be charged. This option is only available for subscription upgrade.
  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#immediate_and_charge_prorated_price
  static const int IMMEDIATE_AND_CHARGE_PRORATED_PRICE = 2;

  /// Replacement takes effect immediately, and the new price will be charged on next recurrence time. The billing cycle stays the same.
  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#immediate_without_proration
  static const int IMMEDIATE_WITHOUT_PRORATION = 3;

  /// Replacement takes effect immediately, and the remaining time will be prorated and credited to the user. This is the current default behavior.
  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#immediate_with_time_proration
  static const int IMMEDIATE_WITH_TIME_PRORATION = 1;

  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#unknown_subscription_upgrade_downgrade_policy
  static const int UNKNOWN_SUBSCRIPTION_UPGRADE_DOWNGRADE_POLICY = 0;
}
