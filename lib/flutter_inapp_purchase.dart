import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

import 'utils.dart';
import 'modules.dart';

export 'modules.dart';

class FlutterInappPurchase {
  /// A list-based enumeration of in-app purchase types
  static final List<String> _typeInApp = [
    'inapp',
    'subs',
  ];

  static StreamController<PurchasedItem> _purchaseController;
  static StreamSubscription _purchaseSub;
  static Stream<PurchasedItem> get onAdditionalSuccessPurchaseIOS => _purchaseController.stream;

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  static const MethodChannel _channel = const MethodChannel('flutter_inapp');

  /// Returns the platform version on `Android` and `iOS`.
  ///
  /// eg, `Android 5.1.1`
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Consumes all items on `Android`.
  ///
  /// Particularly useful for removing all consumable items.
  static Future get consumeAllItems async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('consumeAllItems');
      return result;
    } else if (Platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Prepares `Android` to purchase items.
  ///
  /// Must be called on `Android` before purchasing.
  /// On `iOS` this just checks if the client can make payments.
  @deprecated
  static Future<String> get prepare async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('prepare');
      return result;
    } else if (Platform.isIOS) {
      final String result = await _channel.invokeMethod('canMakePayments');
      return result;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// InitConnection `Android` to purchase items.
  ///
  /// Must be called on `Android` before purchasing.
  /// On `iOS` this just checks if the client can make payments.
  static Future<String> get initConnection async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('prepare');
      return result;
    } else if (Platform.isIOS) {
      final String result = await _channel.invokeMethod('canMakePayments');
      return result;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves a list of products from the store on `Android` and `iOS`.
  ///
  /// `iOS` also returns subscriptions.
  static Future<List<IAPItem>> getProducts(List<String> skus) async {
    if (skus == null || skus.contains(null)) return [];
    skus = skus.toList();
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[0],
          'skus': skus,
        },
      );

      return extractItems(result);
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves subscriptions on `Android` and `iOS`.
  ///
  /// `iOS` also returns non-subscription products.
  static Future<List<IAPItem>> getSubscriptions(List<String> skus) async {
    if (skus == null || skus.contains(null)) return [];
    skus = skus.toList();
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[1],
          'skus': skus,
        },
      );

      return extractItems(result);
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves the user's purchase history on `Android` and `iOS` regardless of consumption status.
  ///
  /// Purchase history includes all types of products.
  /// Identical to [getAvailablePurchases] on `iOS`.
  static Future<List<PurchasedItem>> getPurchaseHistory() async {
    if (Platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': _typeInApp[0],
        },
      );

      dynamic result2 = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': _typeInApp[1],
        },
      );

      return extractPurchased(result1) + extractPurchased(result2);
    } else if (Platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Get all non-consumed purchases made on `Android` and `iOS`.
  ///
  /// This is identical to [getPurchaseHistory] on `iOS`
  static Future<List<PurchasedItem>> getAvailablePurchases() async {
    if (Platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': _typeInApp[0],
        },
      );

      dynamic result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': _typeInApp[1],
        },
      );

      return extractPurchased(result1) + extractPurchased(result2);
    } else if (Platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Purchase a product on `Android` or `iOS`.
  ///
  /// Identical to [buySubscription] on `iOS`.
  static Future<PurchasedItem> buyProduct(String sku) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel
          .invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[0],
        'sku': sku,
        'oldSku': null, //TODO can this be removed?
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);

      return item;
    } else if (Platform.isIOS) {
      try {
        dynamic result = await _channel.invokeMethod(
            'buyProductWithFinishTransaction', <String, dynamic>{
          'sku': sku,
        });
        result = json.encode(result);

        Map<String, dynamic> param = json.decode(result.toString());
        PurchasedItem item = PurchasedItem.fromJSON(param);
        return item;
      } catch (err) {
        print('Caused err. Set additionalSuccessPurchaseListenerIOS.');
        print(err);
        await _addAdditionalSuccessPurchaseListenerIOS();
        _purchaseSub = onAdditionalSuccessPurchaseIOS.listen((data) {
          _removePurchaseListener();
          Map<String, dynamic> param = json.decode(data.toString());
          PurchasedItem item = PurchasedItem.fromJSON(param);
          return item;
        });
      }
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Purchase a subscription on `Android` or `iOS`.
  ///
  /// **NOTICE** second parameter is required on `Android`.
  ///
  /// Identical to [buyProduct] on `iOS`.
  static Future<PurchasedItem> buySubscription(String sku,
      {String oldSku}) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel
          .invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[1],
        'sku': sku,
        'oldSku': oldSku,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      try {
        dynamic result = await _channel.invokeMethod(
            'buyProductWithFinishTransaction', <String, dynamic>{
          'sku': sku,
        });
        result = json.encode(result);

        Map<String, dynamic> param = json.decode(result.toString());
        PurchasedItem item = PurchasedItem.fromJSON(param);
        return item;
      } catch (err) {
        print('Caused err. Set additionalSuccessPurchaseListenerIOS.');
        print(err);
        await _addAdditionalSuccessPurchaseListenerIOS();
        _purchaseSub = onAdditionalSuccessPurchaseIOS.listen((data) {
          _removePurchaseListener();
          Map<String, dynamic> param = json.decode(data.toString());
          PurchasedItem item = PurchasedItem.fromJSON(param);
          return item;
        });
      }
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Consumes a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose consumable purchases are consumed at the time of purchase.
  static Future<String> consumePurchase(String token) async {
    if (Platform.isAndroid) {
      String result =
          await _channel.invokeMethod('consumeProduct', <String, dynamic>{
        'token': token,
      });

      return result;
    } else if (Platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// End Play Store connection on `Android`.
  ///
  /// Absolutely necessary to call this when done with the Play Store.
  ///
  /// No effect on `iOS`, whose store connection is always available.
  static Future<String> get endConnection async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('endConnection');
      return result;
    } else if (Platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Buy a product without finishing the transaction on `iOS`.
  ///
  /// This allows you to perform server-side validation before finalizing the transaction on screen.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  @deprecated
  static Future<PurchasedItem> buyProductWithoutFinishTransaction(
      String sku) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel
          .invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[0],
        'sku': sku,
        'oldSku': null,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
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
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Finish a transaction on `iOS`.
  ///
  /// Call this after finalizing server-side validation of the reciept.
  ///
  /// No effect on `Android`, who does not allow this type of functionality.
  static Future<String> finishTransaction() async {
    if (Platform.isAndroid) {
      return 'no-ops in android.';
    } else if (Platform.isIOS) {
      String result = await _channel.invokeMethod('finishTransaction');
      return result;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Retrieves a list of products that have been attempted to purchase through the App Store `iOS` only.
  ///
  static Future<List<IAPItem>> getAppStoreInitiatedProducts() async {
    if (Platform.isAndroid) {
      return List<IAPItem>();
    } else if (Platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAppStoreInitiatedProducts');

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Check if a subscription is active on `Android` and `iOS`.
  ///
  /// This is a quick and dirty way to check if a subscription is active.
  /// It is highly recommended to do server-side validation for all subscriptions.
  /// This method is NOT secure and untested in production.
  static Future<bool> checkSubscribed({
    String sku,
    Duration duration: const Duration(days: 30),
    Duration grace: const Duration(days: 3),
  }) async {
    if (Platform.isIOS) {
      var history = await FlutterInappPurchase.getPurchaseHistory();

      for (var purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (Platform.isAndroid) {
      var purchases = await FlutterInappPurchase.getAvailablePurchases();

      for (var purchase in purchases) {
        if (purchase.productId == sku) return true;
      }

      return false;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
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
  static Future<http.Response> validateReceiptIos({
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
  static Future<http.Response> validateReceiptAndroid({
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
    return await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );
  }

  /// Add additional success purchase listener to iOS when purchase failed
  ///
  /// In iOS, purchase could be failed randomly. See the reference: https://github.com/dooboolab/react-native-iap/issues/307
  /// To make your purchase flow confidential, use below method. Checkout how this is used in `example` project.
  static Future<void> _addAdditionalSuccessPurchaseListenerIOS() async {
    if (Platform.isIOS) {
      if (_purchaseController == null) {
        _purchaseController = new StreamController.broadcast();
      }
      _channel.setMethodCallHandler((MethodCall call) {
        switch (call.method) {
          case "iap-purchase-event":
            Map<String, dynamic> result = jsonDecode(call.arguments);
            _purchaseController.add(new PurchasedItem.fromJSON(result));
            _removePurchaseListener();
            break;
          default:
            throw new ArgumentError('Unknown method ${call.method}');
        }
      });
    }
  }

  static Future<void> _removePurchaseListener() async {
    if (_purchaseSub != null) {
      _purchaseSub.cancel();
      _purchaseSub = null;
    }
    if (_purchaseController != null) {
      _purchaseController
        ..add(null)
        ..close();
      _purchaseController = null;
    }
  }
}
