import 'dart:async';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

import 'utils.dart';
import 'modules.dart';

export 'modules.dart';

/// A enumeration of in-app purchase types for Android
/// https://developer.android.com/reference/com/android/billingclient/api/BillingClient.SkuType.html#constants_2
enum _TypeInApp {
  inapp, subs
}

class FlutterInappPurchase {
  static final FlutterInappPurchase instance = new FlutterInappPurchase(_instance);

  static StreamController<PurchasedItem> _purchaseController;
  static Stream<PurchasedItem> get purchaseUpdated => _purchaseController.stream;

  static StreamController<PurchaseErrorItem> _purchaseErrorController;
  static Stream<PurchaseErrorItem> get purchaseError => _purchaseErrorController.stream;

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  static final MethodChannel _channel = const MethodChannel('flutter_inapp');
  static MethodChannel get channel => _channel;

  final Platform _pf;
  final http.Client _httpClient;

  static Platform get _platform => _instance._pf;
  static http.Client get _client => _instance._httpClient;


  static FlutterInappPurchase _instance = FlutterInappPurchase(
      FlutterInappPurchase.private(const LocalPlatform()));

  factory FlutterInappPurchase(FlutterInappPurchase instance) {
    _instance = instance;
    return instance;
  }

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform, {http.Client client})
      : _pf = platform,
        _httpClient = client;

  /// Returns the platform version on `Android` and `iOS`.
  ///
  /// eg, `Android 5.1.1`
  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Consumes all items on `Android`.
  ///
  /// Particularly useful for removing all consumable items.
  Future get consumeAllItems async {
    if (_platform.isAndroid) {
      final String result = await _channel.invokeMethod('consumeAllItems');
      return result;
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// InitConnection `Android` to purchase items.
  ///
  /// Must be called on `Android` before purchasing.
  /// On `iOS` this just checks if the client can make payments.
  Future<String> get initConnection async {
    if (_platform.isAndroid) {
      _setPurchaseListener();
      final String result = await _channel.invokeMethod('initConnection');
      return result;
    } else if (_platform.isIOS) {
      _setPurchaseListener();
      final String result = await _channel.invokeMethod('canMakePayments');
      return result;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves a list of products from the store on `Android` and `iOS`.
  ///
  /// `iOS` also returns subscriptions.
  Future<List<IAPItem>> getProducts(List<String> skus) async {
    if (skus == null || skus.contains(null)) return [];
    skus = skus.toList();
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.inapp),
          'skus': skus,
        },
      );
      print('result $result');
      return extractItems(result);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
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
  Future<List<IAPItem>> getSubscriptions(List<String> skus) async {
    if (skus == null || skus.contains(null)) return [];
    skus = skus.toList();
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.subs),
          'skus': skus,
        },
      );

      return extractItems(result);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
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
  Future<List<PurchasedItem>> getPurchaseHistory() async {
    if (_platform.isAndroid) {
      Future<dynamic> getInappPurchaseHistory = _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.inapp),
        },
      );

      Future<dynamic> getSubsPurchaseHistory = _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.subs),
        },
      );

      List<dynamic> results = await Future.wait(
          [getInappPurchaseHistory, getSubsPurchaseHistory]);

      return results.reduce((result1, result2) =>
      extractPurchased(result1) + extractPurchased(result2));
    } else if (_platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Get all non-consumed purchases made on `Android` and `iOS`.
  ///
  /// This is identical to [getPurchaseHistory] on `iOS`
  Future<List<PurchasedItem>> getAvailablePurchases() async {
    if (_platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.inapp),
        },
      );

      dynamic result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': EnumUtil.getValueString(_TypeInApp.subs),
        },
      );

      return extractPurchased(result1) + extractPurchased(result2);
    } else if (_platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Request a purchase on `Android` or `iOS`.
  /// Result will be received in `purchaseUpdated` listener or `purchaseError` listener.
  ///
  /// Identical to [buySubscription] on `iOS`.
  Future<void> requestPurchase(String sku) async {
    if (_platform.isAndroid) {
      await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': EnumUtil.getValueString(_TypeInApp.inapp),
        'sku': sku,
        'oldSku': null,
        'prorationMode': -1,
      });
    } else if (_platform.isIOS) {
      await _channel.invokeMethod(
        'buyProductWithFinishTransaction', <String, dynamic>{
        'sku': sku,
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
  /// Identical to [requestPurchase] on `iOS`.
  Future<void> requestSubscription(String sku,
      {String oldSku, int prorationMode}) async {
    if (_platform.isAndroid) {
      await _channel
          .invokeMethod('buyItemByType', <String, dynamic>{
        'type': EnumUtil.getValueString(_TypeInApp.subs),
        'sku': sku,
        'oldSku': oldSku,
        'prorationMode': prorationMode ?? -1,
      });
    } else if (_platform.isIOS) {
      await _channel.invokeMethod(
        'buyProductWithFinishTransaction', <String, dynamic>{
        'sku': sku,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Acknowledge a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose iap purchases are consumed at the time of purchase.
  Future<String> acknowledgePurchaseAndroid(String token, { String developerPayload }) async {
    if (_platform.isAndroid) {
      String result =
          await _channel.invokeMethod('acknowledgePurchase', <String, dynamic>{
        'token': token,
        'developerPayload': developerPayload,
      });

      return result;
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }


  /// Consumes a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose consumable purchases are consumed at the time of purchase.
  Future<String> consumePurchaseAndroid(String token, { String developerPayload }) async {
    if (_platform.isAndroid) {
      String result =
          await _channel.invokeMethod('consumeProduct', <String, dynamic>{
        'token': token,
        'developerPayload': developerPayload,
      });

      return result;
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// End Play Store connection on `Android`.
  ///
  /// Absolutely necessary to call this when done with the Play Store.
  ///
  /// No effect on `iOS`, whose store connection is always available.
  Future<String> get endConnection async {
    if (_platform.isAndroid) {
      final String result = await _channel.invokeMethod('endConnection');
      _removePurchaseListener();
      return result;
    } else if (_platform.isIOS) {
      _removePurchaseListener();
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Buy a product without finishing the transaction on `iOS`.
  ///
  /// This allows you to perform server-side validation before finalizing the transaction on screen.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  @deprecated
  Future<PurchasedItem> buyProductWithoutFinishTransaction(
      String sku) async {
    if (_platform.isAndroid) {
      dynamic result = await _channel
          .invokeMethod('buyItemByType', <String, dynamic>{
        'type': EnumUtil.getValueString(_TypeInApp.inapp),
        'sku': sku,
        'oldSku': null,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
          'buyProductWithoutFinishTransaction', <String, dynamic>{
        'sku': sku,
      });
      result = json.encode(result);

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Finish a transaction on `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  Future<String> finishTransaction() async {
    if (_platform.isAndroid) {
      return 'no-ops in android.';
    } else if (_platform.isIOS) {
      String result = await _channel.invokeMethod('finishTransaction');
      return result;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves a list of products that have been attempted to purchase through the App Store `iOS` only.
  ///
  Future<List<IAPItem>> getAppStoreInitiatedProducts() async {
    if (_platform.isAndroid) {
      return List<IAPItem>();
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
    String sku,
    Duration duration: const Duration(days: 30),
    Duration grace: const Duration(days: 3),
  }) async {
    if (_platform.isIOS) {
      var history = await getPurchaseHistory();

      for (var purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (_platform.isAndroid) {
      var purchases = await getAvailablePurchases();

      for (var purchase in purchases) {
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
    Map<String, String> receiptBody,
    bool isTest = true,
  }) async {
    assert(receiptBody != null);
    assert(isTest != null);

    final String url = isTest
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';
    return await http.post(
      url,
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
    String packageName,
    String productId,
    String productToken,
    String accessToken,
    bool isSubscription = false,
  }) async {
    assert(packageName != null);
    assert(productId != null);
    assert(productToken != null);
    assert(accessToken != null);

    final String type = isSubscription ? 'subscriptions' : 'products';
    final String url =
        'https://www.googleapis.com/androidpublisher/v2/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken';
    return await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );
  }

  Future<void> _setPurchaseListener() async {
    if (_purchaseController == null) {
      _purchaseController = new StreamController.broadcast();
    }

    if (_purchaseErrorController == null) {
      _purchaseErrorController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "purchase-updated":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _purchaseController.add(new PurchasedItem.fromJSON(result));
          break;
        case "purchase-error":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _purchaseErrorController.add(new PurchaseErrorItem.fromJSON(result));
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method}');
      }
      return null;
    });
  }

  Future<void> _removePurchaseListener() async {
    if (_purchaseController != null) {
      _purchaseController
        ..add(null)
        ..close();
      _purchaseController = null;
    } else if (_purchaseErrorController != null) {
      _purchaseErrorController
        ..add(null)
        ..close();
      _purchaseErrorController = null;
    }
  }
}
