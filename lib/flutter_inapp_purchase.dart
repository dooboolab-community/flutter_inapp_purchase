import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';

import 'Store.dart';
import 'modules.dart';
import 'utils.dart';

export 'modules.dart';

/// A enumeration of in-app purchase types for Android
/// https://developer.android.com/reference/com/android/billingclient/api/BillingClient.ProductType
enum _TypeInApp { inapp, subs }

class FlutterInappPurchase {
  static FlutterInappPurchase instance =
      FlutterInappPurchase(FlutterInappPurchase.private(const LocalPlatform()));

  static StreamController<PurchasedItem?>? _purchaseController;

  static Stream<PurchasedItem?> get purchaseUpdated =>
      _purchaseController!.stream;

  static StreamController<PurchaseResult?>? _purchaseErrorController;

  static Stream<PurchaseResult?> get purchaseError =>
      _purchaseErrorController!.stream;

  static StreamController<ConnectionResult>? _connectionController;

  static Stream<ConnectionResult> get connectionUpdated =>
      _connectionController!.stream;

  static StreamController<String?>? _purchasePromotedController;

  static Stream<String?> get purchasePromoted =>
      _purchasePromotedController!.stream;

  static StreamController<int?>? _onInAppMessageController;
  static Stream<int?> get inAppMessageAndroid =>
      _onInAppMessageController!.stream;

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  static final MethodChannel _channel = const MethodChannel('flutter_inapp');

  static MethodChannel get channel => _channel;

  final Platform _pf;
  late http.Client _httpClient;

  static Platform get _platform => instance._pf;

  static http.Client get _client => instance._httpClient;

  factory FlutterInappPurchase(FlutterInappPurchase _instance) {
    instance = _instance;
    return instance;
  }

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform, {http.Client? client})
      : _pf = platform,
        _httpClient = client ?? http.Client();

  /// Consumes all items on `Android`.
  ///
  /// Particularly useful for removing all consumable items.
  Future consumeAll() async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('consumeAllItems');
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Initializes iap features for both `Android` and `iOS`.
  ///
  /// This must be called on `Android` and `iOS` before purchasing.
  /// On `iOS`, it also checks if the client can make payments.
  Future<String?> initialize() async {
    if (_platform.isAndroid) {
      await _setPurchaseListener();
      return await _channel.invokeMethod('initConnection');
    } else if (_platform.isIOS) {
      await _setPurchaseListener();
      return await _channel.invokeMethod('canMakePayments');
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  Future<bool> isReady() async {
    if (_platform.isAndroid) {
      return (await _channel.invokeMethod<bool?>('isReady')) ?? false;
    }
    if (_platform.isIOS) {
      return Future.value(true);
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  Future<bool> manageSubscription(String sku, String packageName) async {
    if (_platform.isAndroid) {
      return (await _channel.invokeMethod<bool?>(
            'manageSubscription',
            <String, dynamic>{
              'sku': sku,
              'packageName': packageName,
            },
          )) ??
          false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  Future<bool> openPlayStoreSubscriptions() async {
    if (_platform.isAndroid) {
      return (await _channel
              .invokeMethod<bool?>('openPlayStoreSubscriptions')) ??
          false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  Future<Store> getStore() async {
    if (_platform.isIOS) {
      return Future.value(Store.appStore);
    }
    if (_platform.isAndroid) {
      final store = await _channel.invokeMethod<String?>('getStore');
      if (store == "play_store") return Store.playStore;
      if (store == "amazon") return Store.amazon;
      return Store.none;
    }
    return Future.value(Store.none);
  }

  /// Retrieves a list of products from the store on `Android` and `iOS`.
  ///
  /// `iOS` also returns subscriptions.
  Future<List<IAPItem>> getProducts(List<String> productIds) async {
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getProducts',
        <String, dynamic>{
          'productIds': productIds.toList(),
        },
      );
      return extractItems(result);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        <String, dynamic>{
          'skus': productIds.toList(),
        },
      );
      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves subscriptions on `Android` and `iOS`.
  ///
  /// `iOS` also returns non-subscription products.
  Future<List<IAPItem>> getSubscriptions(List<String> productIds) async {
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getSubscriptions',
        <String, dynamic>{
          'productIds': productIds.toList(),
        },
      );
      return extractItems(result);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        <String, dynamic>{
          'skus': productIds.toList(),
        },
      );
      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves the user's purchase history on `Android` and `iOS` regardless of consumption status.
  ///
  /// Purchase history includes all types of products.
  /// Identical to [getAvailablePurchases] on `iOS`.
  Future<List<PurchasedItem>?> getPurchaseHistory() async {
    if (_platform.isAndroid) {
      final dynamic getInappPurchaseHistory = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': describeEnum(_TypeInApp.inapp),
        },
      );

      final dynamic getSubsPurchaseHistory = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': describeEnum(_TypeInApp.subs),
        },
      );

      return extractPurchased(getInappPurchaseHistory)! +
          extractPurchased(getSubsPurchaseHistory)!;
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Android only, Google Play will show users messaging during grace period
  /// and account hold once per day and provide them an opportunity to fix their
  /// payment without leaving the app
  Future<String?> showInAppMessageAndroid() async {
    if (!_platform.isAndroid) return Future.value("");
    _onInAppMessageController ??= StreamController.broadcast();
    return await _channel.invokeMethod('showInAppMessages');
  }

  /// Get all non-consumed purchases made on `Android` and `iOS`.
  ///
  /// This is identical to [getPurchaseHistory] on `iOS`
  Future<List<PurchasedItem>?> getAvailablePurchases() async {
    if (_platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': describeEnum(_TypeInApp.inapp),
        },
      );

      dynamic result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': describeEnum(_TypeInApp.subs),
        },
      );
      return extractPurchased(result1)! + extractPurchased(result2)!;
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Request a purchase on `Android` or `iOS`.
  /// Result will be received in `purchaseUpdated` listener or `purchaseError` listener.
  ///
  /// Check [AndroidProrationMode] for valid proration values
  /// Identical to [requestSubscription] on `iOS`.
  /// [purchaseTokenAndroid] is used when upgrading subscriptions and sets the old purchase token
  /// [offerTokenIndex] is now required for billing 5.0, if upgraded from billing 4.0 this will default to 0
  Future requestPurchase(String productId,
      {String? obfuscatedAccountId,
      String? purchaseTokenAndroid,
      String? obfuscatedProfileIdAndroid,
      int? offerTokenIndex}) async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': describeEnum(_TypeInApp.inapp),
        'productId': productId,
        'prorationMode': -1,
        'obfuscatedAccountId': obfuscatedAccountId,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
        'offerTokenIndex': offerTokenIndex
      });
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('buyProduct', <String, dynamic>{
        'sku': productId,
        'forUser': obfuscatedAccountId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Request a subscription on `Android` or `iOS`.
  /// Result will be received in `purchaseUpdated` listener or `purchaseError` listener.
  ///
  /// **NOTICE** second parameter is required on `Android`.
  ///
  /// Check [AndroidProrationMode] for valid proration values
  /// Identical to [requestPurchase] on `iOS`.
  /// [purchaseTokenAndroid] is used when upgrading subscriptions and sets the old purchase token
  /// [offerTokenIndex] is now required for billing 5.0, if upgraded from billing 4.0 this will default to 0
  Future requestSubscription(
    String productId, {
    int? prorationModeAndroid,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    String? purchaseTokenAndroid,
    int? offerTokenIndex,
  }) async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': describeEnum(_TypeInApp.subs),
        'productId': productId,
        'prorationMode': prorationModeAndroid ?? -1,
        'obfuscatedAccountId': obfuscatedAccountIdAndroid,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
        'offerTokenIndex': offerTokenIndex,
      });
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('buyProduct', <String, dynamic>{
        'sku': productId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Add Store Payment (iOS only)
  /// Indicates that the App Store purchase should continue from the app instead of the App Store.
  ///
  /// @returns {Future<String>}
  Future<String?> getPromotedProductIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('getPromotedProduct');
    }
    return null;
  }

  /// Add Store Payment (iOS only)
  /// Indicates that the App Store purchase should continue from the app instead of the App Store.
  ///
  /// @returns {Future} will receive result from `purchasePromoted` listener.
  Future requestPromotedProductIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('requestPromotedProduct');
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
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
      return await _channel
          .invokeMethod('requestProductWithOfferIOS', <String, dynamic>{
        'sku': sku,
        'forUser': forUser,
        'withOffer': withOffer,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Buy product with quantity
  ///
  /// @returns {Future} will receive result from `purchaseUpdated` listener.
  Future requestPurchaseWithQuantityIOS(
    String sku,
    int quantity,
  ) async {
    if (_platform.isIOS) {
      return await _channel
          .invokeMethod('requestProductWithQuantityIOS', <String, dynamic>{
        'sku': sku,
        'quantity': quantity.toString(),
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Get the pending purchases in IOS.
  ///
  /// @returns {Future<List<PurchasedItem>>}
  Future<List<PurchasedItem>?> getPendingTransactionsIOS() async {
    if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getPendingTransactions',
      );

      return extractPurchased(json.encode(result));
    }
    return [];
  }

  /// Acknowledge a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose iap purchases are consumed at the time of purchase.
  Future<String?> acknowledgePurchaseAndroid(String token) async {
    if (_platform.isAndroid) {
      return await _channel
          .invokeMethod('acknowledgePurchase', <String, dynamic>{
        'token': token,
      });
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
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
      return await _channel.invokeMethod('consumeProduct', <String, dynamic>{
        'token': token,
      });
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// End Play Store connection on `Android` and remove iap observer in `iOS`.
  ///
  /// Absolutely necessary to call this when done with the payment.
  Future<String?> finalize() async {
    if (_platform.isAndroid) {
      final String? result = await _channel.invokeMethod('endConnection');
      _removePurchaseListener();
      return result;
    } else if (_platform.isIOS) {
      final String? result = await _channel.invokeMethod('endConnection');
      _removePurchaseListener();
      return result;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Finish a transaction on `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  Future<String?> finishTransactionIOS(String transactionId) async {
    if (_platform.isAndroid) {
      return 'no ops in android';
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('finishTransaction', <String, dynamic>{
        'transactionIdentifier': transactionId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Finish a transaction on both `android` and `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  Future<String?> finishTransaction(PurchasedItem purchasedItem,
      {bool isConsumable = false}) async {
    if (_platform.isAndroid) {
      if (isConsumable) {
        return await _channel.invokeMethod('consumeProduct', <String, dynamic>{
          'token': purchasedItem.purchaseToken,
        });
      } else {
        if (purchasedItem.isAcknowledgedAndroid == true) {
          return Future.value(null);
        } else {
          return await _channel
              .invokeMethod('acknowledgePurchase', <String, dynamic>{
            'token': purchasedItem.purchaseToken,
          });
        }
      }
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('finishTransaction', <String, dynamic>{
        'transactionIdentifier': purchasedItem.transactionId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Clear all remaining transaction on `iOS`.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  Future<String?> clearTransactionIOS() async {
    if (_platform.isAndroid) {
      return 'no-ops in android.';
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('clearTransaction');
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves a list of products that have been attempted to purchase through the App Store `iOS` only.
  ///
  Future<List<IAPItem>> getAppStoreInitiatedProducts() async {
    if (_platform.isAndroid) {
      return <IAPItem>[];
    } else if (_platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAppStoreInitiatedProducts');

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
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
      var history = await getPurchaseHistory();

      if (history == null) {
        return false;
      }

      for (var purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate!);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (_platform.isAndroid) {
      var purchases = await (getAvailablePurchases());

      for (var purchase in purchases ?? []) {
        if (purchase.productId == sku) return true;
      }

      return false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
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
    final String url = isTest
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';
    return await _client.post(
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
    return await _client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );
  }

  Future _setPurchaseListener() async {
    _purchaseController ??= StreamController.broadcast();
    _purchaseErrorController ??= StreamController.broadcast();
    _connectionController ??= StreamController.broadcast();
    _purchasePromotedController ??= StreamController.broadcast();

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "purchase-updated":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _purchaseController!.add(PurchasedItem.fromJSON(result));
          break;
        case "purchase-error":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _purchaseErrorController!.add(PurchaseResult.fromJSON(result));
          break;
        case "connection-updated":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _connectionController!.add(ConnectionResult.fromJSON(result));
          break;
        case "iap-promoted-product":
          String? productId = call.arguments;
          _purchasePromotedController!.add(productId);
          break;
        case "on-in-app-message":
          final int code = call.arguments;
          _onInAppMessageController?.add(code);
          break;
        default:
          throw ArgumentError('Unknown method ${call.method}');
      }
      return Future.value(null);
    });
  }

  Future _removePurchaseListener() async {
    _purchaseController
      ?..add(null)
      ..close();
    _purchaseController = null;

    _purchaseErrorController
      ?..add(null)
      ..close();
    _purchaseErrorController = null;
  }

  Future<String> showPromoCodesIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('showRedeemCodesIOS');
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }
}

/// A list of valid values for ProrationMode parameter
/// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode
class AndroidProrationMode {
  /// Replacement takes effect immediately, and the user is charged full price of new plan and is given a full billing cycle of subscription, plus remaining prorated time from the old plan.
  /// https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.ProrationMode#IMMEDIATE_AND_CHARGE_FULL_PRICE
  static const int IMMEDIATE_AND_CHARGE_FULL_PRICE = 5;

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
