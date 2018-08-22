import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import 'utils.dart';
import 'modules.dart';

export 'modules.dart';

class FlutterInappPurchase {
  static final List<String> _typeInApp = [
    'inapp',
    'subs',
  ];

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
  /// Must be done on `Android` before purchasing.
  /// On `iOS` this just checks if the client can make payments.
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

  /// Retrieves products from the store on `Android` and `iOS`.
  ///
  /// `iOS` also returns subscriptions.
  static Future<List<IAPItem>> getProducts(List<String> skus) async {
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

  /// Retrieves the user's purchase history on `Android` and `iOS`.
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
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Get all non-consumed purchases made on `Android` and `iOS`
  ///
  /// This is identical to [getPurchaseHistory] on `iOS`
  static Future<List<IAPItem>> getAvailablePurchases() async {
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

      return extractItems(result1) + extractItems(result2);
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }

  /// Purchase a product on `Android` or `iOS`.
  ///
  /// Identical to [buySubscription] on `iOS`.
  static Future<PurchasedItem> buyProduct(String sku, {String oldSku}) async {
    if (Platform.isAndroid) {
      dynamic result =
          await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[0],
        'sku': sku,
        'oldSku': null,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);

      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel
          .invokeMethod('buyProductWithFinishTransaction', <String, dynamic>{
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

  /// Purchase a subscription on `Android` or `iOS`.
  ///
  /// Identical to [buyProduct] on `iOS`.
  static Future<PurchasedItem> buySubscription(String sku,
      {String oldSku}) async {
    if (Platform.isAndroid) {
      dynamic result =
          await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[1],
        'sku': sku,
        'oldSku': oldSku,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel
          .invokeMethod('buyProductWithFinishTransaction', <String, dynamic>{
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

  /// Consumes a purchase on `Android`.
  ///
  /// No effect on `iOS`, whose consumable purchases are automatically consumed.
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
  /// This may be useful if you are using server side reciept validation.
  /// TODO: improve this comment
  static Future<PurchasedItem> buyProductWithoutFinishTransaction(
      String sku) async {
    if (Platform.isAndroid) {
      dynamic result =
          await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': _typeInApp[0],
        'sku': sku,
        'oldSku': null,
      });

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('buyProductWithoutFinishTransaction');
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
  /// No effect on `Android`.
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

  /// Check if a subscription is active on `Android` and `iOS`.
  ///
  /// This is a quick and dirty way to check if a subscription is active.
  /// It is highly recommended to do server-side validation for all subscriptions.
  static Future<bool> checkSubscribed({
    String sku,
    Duration duration: const Duration(days: 30),
    Duration grace: const Duration(days: 3),
  }) async {
    await FlutterInappPurchase.prepare;

    if (Platform.isIOS) {
      var history = await FlutterInappPurchase.getPurchaseHistory();
      FlutterInappPurchase.endConnection;

      for (var purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (Platform.isAndroid) {
      var purchases = await FlutterInappPurchase.getAvailablePurchases();
      FlutterInappPurchase.endConnection;

      for (var purchase in purchases) {
        if (purchase.productId == sku) return true;
      }

      return false;
    }
    throw PlatformException(
        code: Platform.operatingSystem, message: "platform not supported");
  }
}
