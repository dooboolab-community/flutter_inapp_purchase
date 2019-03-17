import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  group('FlutterInappPurchase', () {
    group('platformVersion', () {
      final List<MethodCall> log = <MethodCall>[];
      setUp(() {
        FlutterInappPurchase(FlutterInappPurchase.private(FakePlatform()));

        FlutterInappPurchase.channel
            .setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          return "Android 5.1.1";
        });
      });

      tearDown(() {
        FlutterInappPurchase.channel.setMethodCallHandler(null);
      });

      test('invoke correct method', () async {
        await FlutterInappPurchase.platformVersion;
        expect(log, <Matcher>[
          isMethodCall(
            'getPlatformVersion',
            arguments: null,
          ),
        ]);
      });

      test('returns correct result', () async {
        expect(await FlutterInappPurchase.platformVersion, "Android 5.1.1");
      });
    });

    group('consumeAllItems', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return "All items have been consumed";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.consumeAllItems;
          expect(log, <Matcher>[
            isMethodCall('consumeAllItems', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.consumeAllItems,
              "All items have been consumed");
        });
      });

      group('For iOS', () {
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.consumeAllItems, "no-ops in ios");
        });
      });
    });

    group('initConnection', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return "Billing client ready";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.initConnection;
          expect(log, <Matcher>[
            isMethodCall('prepare', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.initConnection,
              "Billing client ready");
        });
      });

      group('For iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return "true";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.initConnection;
          expect(log, <Matcher>[
            isMethodCall('canMakePayments', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.initConnection, "true");
        });
      });
    });

    group('getProducts', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = List()..add("testsku");

        List<IAPItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getProducts(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItemsByType',
              arguments: <String, dynamic>{
                'type': 'inapp',
                'skus': skus,
              },
            ),
          ]);
        });
      });

      group('For iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = List()..add("testsku");

        List<IAPItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getProducts(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItems',
              arguments: <String, dynamic>{
                'skus': skus,
              },
            ),
          ]);
        });
      });
    });

    group('getSubscriptions', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = List()..add("testsku");

        List<IAPItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getSubscriptions(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItemsByType',
              arguments: <String, dynamic>{
                'type': 'subs',
                'skus': skus,
              },
            ),
          ]);
        });
      });

      group('For iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = List()..add("testsku");

        List<IAPItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getSubscriptions(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItems',
              arguments: <String, dynamic>{
                'skus': skus,
              },
            ),
          ]);
        });
      });
    });

    group('getPurchaseHistory', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];

        List<PurchasedItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getPurchaseHistory();
          expect(log, <Matcher>[
            isMethodCall(
              'getPurchaseHistoryByType',
              arguments: <String, dynamic>{
                'type': 'inapp',
              },
            ),
            isMethodCall(
              'getPurchaseHistoryByType',
              arguments: <String, dynamic>{
                'type': 'subs',
              },
            ),
          ]);
        });
      });

      group('For iOS', () {
        final List<MethodCall> log = <MethodCall>[];

        List<PurchasedItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getPurchaseHistory();
          expect(log, <Matcher>[
            isMethodCall(
              'getAvailableItems',
              arguments: null,
            ),
          ]);
        });
      });
    });

    group('getAvailablePurchases', () {
      group('For Android', () {
        final List<MethodCall> log = <MethodCall>[];

        List<PurchasedItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getAvailablePurchases();
          expect(log, <Matcher>[
            isMethodCall(
              'getAvailableItemsByType',
              arguments: <String, dynamic>{
                'type': 'inapp',
              },
            ),
            isMethodCall(
              'getAvailableItemsByType',
              arguments: <String, dynamic>{
                'type': 'subs',
              },
            ),
          ]);
        });
      });

      group('For iOS', () {
        final List<MethodCall> log = <MethodCall>[];

        List<PurchasedItem> result = List();

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.getAvailablePurchases();
          expect(log, <Matcher>[
            isMethodCall(
              'getAvailableItems',
              arguments: null,
            ),
          ]);
        });
      });
    });

    group('buyProduct', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];

        final String sku = "testsku";
        final String result = """{
            "transactionDate":"1552824902000",
            "transactionId":"testTransactionId",
            "productId":"com.cooni.point1000",
            "transactionReceipt":"testTransactionReciept",
            "purchaseToken":"testPurchaseToken",
            "autoRenewingAndroid":true,
            "dataAndroid":"testDataAndroid",
            "signatureAndroid":"testSignatureAndroid",
            "originalTransactionDateIOS":"1552831136000",
            "originalTransactionIdentifierIOS":"testOriginalTransactionIdentifierIOS"
          }""";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.buyProduct(sku);
          expect(log, <Matcher>[
            isMethodCall(
              'buyItemByType',
              arguments: <String, dynamic>{
                'type': 'inapp',
                'sku': sku,
                'oldSku': null,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          PurchasedItem actual = await FlutterInappPurchase.buyProduct(sku);
          PurchasedItem expected = PurchasedItem.fromJSON(json.decode(result));
          expect(actual.transactionDate, expected.transactionDate);
          expect(actual.transactionId, expected.transactionId);
          expect(actual.productId, expected.productId);
          expect(actual.transactionReceipt, expected.transactionReceipt);
          expect(actual.purchaseToken, expected.purchaseToken);
          expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
          expect(actual.dataAndroid, expected.dataAndroid);
          expect(actual.signatureAndroid, expected.signatureAndroid);
          expect(actual.originalTransactionDateIOS, expected.originalTransactionDateIOS);
          expect(actual.originalTransactionIdentifierIOS, expected.originalTransactionIdentifierIOS);
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        final String sku = "testsku";
        final dynamic result = {
          "transactionDate":"1552824902000",
          "transactionId":"testTransactionId",
          "productId":"com.cooni.point1000",
          "transactionReceipt":"testTransactionReciept",
          "purchaseToken":"testPurchaseToken",
          "autoRenewingAndroid":true,
          "dataAndroid":"testDataAndroid",
          "signatureAndroid":"testSignatureAndroid",
          "originalTransactionDateIOS":"1552831136000",
          "originalTransactionIdentifierIOS":"testOriginalTransactionIdentifierIOS"
        };

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return result;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.buyProduct(sku);
          expect(log, <Matcher>[
            isMethodCall(
              'buyProductWithFinishTransaction',
              arguments: <String, dynamic>{
                'sku': sku,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          PurchasedItem actual = await FlutterInappPurchase.buyProduct(sku);
          PurchasedItem expected = PurchasedItem.fromJSON(result);
          expect(actual.transactionDate, expected.transactionDate);
          expect(actual.transactionId, expected.transactionId);
          expect(actual.productId, expected.productId);
          expect(actual.transactionReceipt, expected.transactionReceipt);
          expect(actual.purchaseToken, expected.purchaseToken);
          expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
          expect(actual.dataAndroid, expected.dataAndroid);
          expect(actual.signatureAndroid, expected.signatureAndroid);
          expect(actual.originalTransactionDateIOS, expected.originalTransactionDateIOS);
          expect(actual.originalTransactionIdentifierIOS, expected.originalTransactionIdentifierIOS);
        });
      });
    });
  });
}
