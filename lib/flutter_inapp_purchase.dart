import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class FlutterInappPurchase {
  static final List<String> _typeInApp = [
    'inapp',
    'subs',
  ];

  static const MethodChannel _channel =
  const MethodChannel('flutter_inapp');

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
    return 'Current platform is not supported';
  }

  static Future<String> get prepare async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('prepare');
      return result;
    } else if (Platform.isIOS) {
      final String result = await _channel.invokeMethod('canMakePayments');
      return result;
    }
    return 'Current platform is not supported';
  }

  static Future<List<IAPItem>> getProducts(List<String> skus) async {
    skus = skus.toList();
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[0],
          'skus': skus,
        },
      );

      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );

      result = json.encode(result);
      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<List<IAPItem>> getSubscriptions(List<String> skus) async {
    skus = skus.toList();
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[1],
          'skus': skus,
        },
      );

      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );

      print('result\n$result');
      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();
      print('result\n$result');
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<List<IAPItem>> getPurchaseHistory() async {
    if (Platform.isAndroid) {
      var result1 = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': _typeInApp[0],
        },
      );

      var result2 = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': _typeInApp[1],
        },
      );

      result1 = json.decode(result1).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      result2 = json.decode(result2).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      var result = new List.from(result1)..addAll(result2);

      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);
      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<List<IAPItem>> getAvailablePurchases() async {
    if (Platform.isAndroid) {
      var result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': _typeInApp[0],
        },
      );

      var result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': _typeInApp[1],
        },
      );

      result1 = json.decode(result1).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      result2 = json.decode(result2).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();

      var result = new List.from(result1)..addAll(result2);

      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);
      result = json.decode(result).map<IAPItem>(
            (product) => new IAPItem.fromJSON(product),
      ).toList();
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<dynamic> buyProduct(String sku, { oldSku }) async {
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[0],
            'sku': sku,
            'oldSku': null,
          }
      );

      result = json.decode(result);
      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod(
          'buyProductWithFinishTransaction',
          <String, dynamic>{
            'sku': sku,
          }
      );
      result = json.encode(result);
      result = json.decode(result);
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<dynamic> buySubscription(String sku, { oldSku }) async {
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[1],
            'sku': sku,
            'oldSku': oldSku,
          }
      );

      result = json.decode(result);
      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod(
          'buyProductWithFinishTransaction',
          <String, dynamic>{
            'sku': sku,
          }
      );
      result = json.encode(result);
      result = json.decode(result);
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<String> consumePurchase(String token) async {
    if (Platform.isAndroid) {
      String result = await _channel.invokeMethod(
          'consumeProduct',
          <String, dynamic>{
            'token': token,
          }
      );

      return result;
    } else if (Platform.isIOS) {
      return 'no-ops in ios';
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  /// android specific
  static Future<String> get endConnection async {
    if (Platform.isAndroid) {
      final String result = await _channel.invokeMethod('endConnection');
      return result;
    } else if (Platform.isIOS) {
      return 'no-ops in ios';
    }
    return 'Current platform is not supported';
  }

  /// ios specific
  static Future<dynamic> buyProductWithoutFinishTransaction(String sku) async {
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[0],
            'sku': sku,
            'oldSku': null,
          }
      );

      result = json.decode(result);
      return result;
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod('buyProductWithoutFinishTransaction');
      result = json.encode(result);
      result = json.decode(result);
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<String> finishTransaction() async {
    if (Platform.isAndroid) {
      return 'no-ops in android.';
    } else if (Platform.isIOS) {
      var result = await _channel.invokeMethod('finishTransaction');
      return result;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }
}

class IAPItem {
  final String productId;
  final String price;
  final String currency;
  final String type;
  final String localizedPrice;
  final String title;
  final String description;

  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'],
        price = json['price'],
        currency = json['currency'],
        type = json['type'],
        localizedPrice = json['localizedPrice'],
        title = json['title'],
        description = json['description']
  ;

  @override
  String toString() {
    return
      'productId: $productId, '
          'price: $price, '
          'currency: $currency, '
          'type: $type, '
          'localizedPrice: $localizedPrice, '
          'title: $title, '
          'description: $title'
    ;
  }


}
