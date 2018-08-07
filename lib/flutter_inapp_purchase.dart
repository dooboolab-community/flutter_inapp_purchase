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
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[0],
          'skus': skus,
        },
      );

      List list = json.decode(result.toString());
      List<IAPItem> products = list.map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      return products;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );

      result = json.encode(result);
      List list = json.decode(result.toString());
      List<IAPItem> products = list.map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      return products;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<PurchasedItem> getSubscriptions(List<String> skus) async {
    skus = skus.toList();
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getItemsByType',
        <String, dynamic>{
          'type': _typeInApp[1],
          'skus': skus,
        },
      );

      Map<String, String> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        {
          'skus': skus,
        },
      );
      result = json.encode(result);

      Map<String, String> param = json.decode(result.toString());
      PurchasedItem purchase = new PurchasedItem.fromJSON(param);
      return purchase;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<List<IAPItem>> getPurchaseHistory() async {
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

      List<String> decoded1 = json.decode(result1.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      List<String> decoded2 = json.decode(result2.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      List<IAPItem> items = new List<dynamic>.from(decoded1)..addAll(decoded2);
      return items;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);
      List<IAPItem> items = json.decode(result.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();
      return items;
    }
    throw new PlatformException(code: Platform.operatingSystem);
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

      List<IAPItem> decoded1 = json.decode(result1.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      List<IAPItem> decoded2 = json.decode(result2.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();

      var items = new List<IAPItem>.from(decoded1)..addAll(decoded2);
      return items;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);

      List<IAPItem> items = json.decode(result.toString()).map<IAPItem>(
            (dynamic product) => new IAPItem.fromJSON(product as Map<String, dynamic>),
      ).toList();
      return items;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<PurchasedItem> buyProduct(String sku, { String oldSku }) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[0],
            'sku': sku,
            'oldSku': null,
          }
      );

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);

      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
          'buyProductWithFinishTransaction',
          <String, dynamic>{
            'sku': sku,
          }
      );
      result = json.encode(result);

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<PurchasedItem> buySubscription(String sku, { String oldSku }) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[1],
            'sku': sku,
            'oldSku': oldSku,
          }
      );

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
          'buyProductWithFinishTransaction',
          <String, dynamic>{
            'sku': sku,
          }
      );
      result = json.encode(result);

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
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
  static Future<PurchasedItem> buyProductWithoutFinishTransaction(String sku) async {
    if (Platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
          'buyItemByType',
          <String, dynamic>{
            'type': _typeInApp[0],
            'sku': sku,
            'oldSku': null,
          }
      );

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
          'buyProductWithoutFinishTransaction'
      );
      result = json.encode(result);

      Map<String, dynamic> param = json.decode(result.toString());
      PurchasedItem item = new PurchasedItem.fromJSON(param);
      return item;
    }
    throw new PlatformException(code: Platform.operatingSystem);
  }

  static Future<String> finishTransaction() async {
    if (Platform.isAndroid) {
      return 'no-ops in android.';
    } else if (Platform.isIOS) {
      String result = await _channel.invokeMethod('finishTransaction');
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
      : productId = json['productId'] as String,
        price = json['price'] as String,
        currency = json['currency'] as String,
        type = json['type'] as String,
        localizedPrice = json['localizedPrice'] as String,
        title = json['title'] as String,
        description = json['description'] as String
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

class PurchasedItem {
  final dynamic transactionDate;
  final String transactionId;
  final String productId;
  final String transactionReceipt;
  final String purchaseToken;

  // Android only
  final bool autoRenewing;
  // Android only
  final String data;
  // Android only
  final String signature;
  
  // iOS only
  final dynamic originalTransactionDate;
  // iOS only
  final String originalTransactionIdentifier;

  PurchasedItem.fromJSON(Map<String, dynamic> json)
    : transactionDate = json['transactionDate'] as dynamic,
      transactionId = json['transactionId'] as String,
      productId = json['productId'] as String,
      transactionReceipt = json['transactionReceipt'] as String,
      purchaseToken = json['purchaseToken'] as String,
      autoRenewing = json['autoRenewing'] as bool,
      data = json['data'] as String,
      signature = json['signature'] as String,
      originalTransactionDate = json['originalTransactionDate'] as dynamic,
      originalTransactionIdentifier = json['originalTransactionIdentifier'] as String
  ;

  @override
  String toString() {
    return
      'transactionDate: $transactionDate, '
      'transactionId: $transactionId, '
      'productId: $productId, '
      'transactionReceipt: $transactionReceipt, '
      'purchaseToken: $purchaseToken, '
      'autoRenewing: $autoRenewing, '
      'data: $data, '
      'signature: $signature, '
      'originalTransactionDate: $originalTransactionDate, '
      'originalTransactionIdentifier: $originalTransactionIdentifier'
    ;
  }
}
