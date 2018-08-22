import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

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

      List list = json.decode(result.toString());
      List<IAPItem> products = list
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

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
      List<IAPItem> products = list
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      return products;
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

      List list = json.decode(result.toString());
      List<IAPItem> products = list
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

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
      List<IAPItem> products = list
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      return products;
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

      List<PurchasedItem> decoded1 = json
          .decode(result1.toString())
          .map<PurchasedItem>(
            (dynamic product) =>
                PurchasedItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      List<PurchasedItem> decoded2 = json
          .decode(result2.toString())
          .map<PurchasedItem>(
            (dynamic product) =>
                PurchasedItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      var items = List<PurchasedItem>.from(decoded1)..addAll(decoded2);
      return items;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);
      List<PurchasedItem> items = json
          .decode(result.toString())
          .map<PurchasedItem>(
            (dynamic product) =>
                PurchasedItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();
      return items;
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

      List<IAPItem> decoded1 = json
          .decode(result1.toString())
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      List<IAPItem> decoded2 = json
          .decode(result2.toString())
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();

      var items = List<IAPItem>.from(decoded1)..addAll(decoded2);
      return items;
    } else if (Platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');
      result = json.encode(result);

      List<IAPItem> items = json
          .decode(result.toString())
          .map<IAPItem>(
            (dynamic product) =>
                IAPItem.fromJSON(product as Map<String, dynamic>),
          )
          .toList();
      return items;
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

class IAPItem {
  final String productId;
  final String price;
  final String currency;
  final String localizedPrice;
  final String title;
  final String description;
  final String introductoryPrice;

  /// ios only
  final String subscriptionPeriodNumberIOS;
  final String subscriptionPeriodUnitIOS;

  /// android only
  final String subscriptionPeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String introductoryPricePeriodAndroid;
  final String freeTrialPeriodAndroid;

  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String,
        price = json['price'] as String,
        currency = json['currency'] as String,
        localizedPrice = json['localizedPrice'] as String,
        title = json['title'] as String,
        description = json['description'] as String,
        introductoryPrice = json['introductoryPrice'] as String,
        subscriptionPeriodNumberIOS =
            json['subscriptionPeriodNumberIOS'] as String,
        subscriptionPeriodUnitIOS = json['subscriptionPeriodUnitIOS'] as String,
        subscriptionPeriodAndroid = json['subscriptionPeriodAndroid'] as String,
        introductoryPriceCyclesAndroid =
            json['introductoryPriceCyclesAndroid'] as String,
        introductoryPricePeriodAndroid =
            json['introductoryPricePeriodAndroid'] as String,
        freeTrialPeriodAndroid = json['freeTrialPeriodAndroid'] as String;

  @override
  String toString() {
    return 'productId: $productId, '
        'price: $price, '
        'currency: $currency, '
        'localizedPrice: $localizedPrice, '
        'title: $title, '
        'description: $title, '
        'introductoryPrice: $introductoryPrice, '
        'subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS, '
        'subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS, '
        'subscriptionPeriodAndroid: $subscriptionPeriodAndroid, '
        'introductoryPriceCyclesAndroid: $introductoryPriceCyclesAndroid, '
        'introductoryPricePeriodAndroid: $introductoryPricePeriodAndroid, '
        'freeTrialPeriodAndroid: $freeTrialPeriodAndroid, ';
  }
}

class PurchasedItem {
  final DateTime transactionDate;
  final String transactionId;
  final String productId;
  final String transactionReceipt;
  final String purchaseToken;

  // Android only
  final bool autoRenewingAndroid;
  final String dataAndroid;
  final String signatureAndroid;

  // iOS only
  final DateTime originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;

  PurchasedItem.fromJSON(Map<String, dynamic> json)
      : transactionDate = DateTime.fromMillisecondsSinceEpoch(
          _toInt(json['transactionDate']),
        ),
        transactionId = json['transactionId'] as String,
        productId = json['productId'] as String,
        transactionReceipt = json['transactionReceipt'] as String,
        purchaseToken = json['purchaseToken'] as String,
        autoRenewingAndroid = json['autoRenewingAndroid'] as bool,
        dataAndroid = json['dataAndroid'] as String,
        signatureAndroid = json['signatureAndroid'] as String,
        originalTransactionDateIOS = DateTime.fromMillisecondsSinceEpoch(
          _toInt(json['originalTransactionDateIOS']),
        ),
        originalTransactionIdentifierIOS =
            json['originalTransactionIdentifierIOS'] as String;

  @override
  String toString() {
    return 'transactionDate: ${transactionDate.toIso8601String()}, '
        'transactionId: $transactionId, '
        'productId: $productId, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'dataAndroid: $dataAndroid, '
        'signatureAndroid: $signatureAndroid, '
        'originalTransactionDateIOS: ${originalTransactionDateIOS.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS';
  }

  static int _toInt(dynamic timestamp) =>
      double.parse(timestamp.toString()).toInt();
}
