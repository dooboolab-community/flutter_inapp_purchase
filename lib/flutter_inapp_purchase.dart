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

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

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

  /// android specific
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

  /// ios specific
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
}
