import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterInappPurchase', () {
    group('showInAppMessageAndroid', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return "ready";
          });
        });
        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.showInAppMessageAndroid();
          expect(log, <Matcher>[
            isMethodCall('showInAppMessages', arguments: null),
          ]);
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          final result =
              await FlutterInappPurchase.instance.showInAppMessageAndroid();
          expect(result, "ready");
        });
      });
    });
    group('consumeAllItems', () {
      group('for Android', () {
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
          await FlutterInappPurchase.instance.consumeAll();
          expect(log, <Matcher>[
            isMethodCall('consumeAllItems', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.consumeAll(),
              "All items have been consumed");
        });
      });

      group('for iOS', () {
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.consumeAll(),
              "no-ops in ios");
        });
      });
    });

    group('initConnection', () {
      group('for Android', () {
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
          await FlutterInappPurchase.instance.initialize();
          expect(log, <Matcher>[
            isMethodCall('initConnection', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.initialize(),
              "Billing client ready");
        });
      });

      group('for iOS', () {
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
          await FlutterInappPurchase.instance.initialize();
          expect(log, <Matcher>[
            isMethodCall('canMakePayments', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.initialize(), "true");
        });
      });
    });

    group('getProducts', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> productIds = []..add("testsku");

        final dynamic result = """[
          {
            "productId": "com.cooni.point1000",
            "price": "120",
            "currency": "JPY",
            "localizedPrice": "¥120",
            "title": "1,000",
            "description": "1000 points 1000P",
            "introductoryPrice": "1001",
            "introductoryPricePaymentModeIOS": "1002",
            "introductoryPriceNumberOfPeriodsIOS": "1003",
            "introductoryPriceSubscriptionPeriodIOS": "1004",
            "subscriptionPeriodUnitIOS": "1",
            "subscriptionPeriodAndroid": "2",
            "subscriptionPeriodNumberIOS": "3",
            "introductoryPriceCyclesAndroid": 4,
            "introductoryPricePeriodAndroid": "5",
            "freeTrialPeriodAndroid": "6",
            "subscriptionOffers": [
              {
                "offerId": "123",
                "basePlanId": "null",
                "offerToken": "1234",
                "pricingPhases": [
                  {
                    "price": "120",
                    "formattedPrice": "¥120",
                    "billingPeriod": "p1m",
                    "currencyCode": "JPY",
                    "recurrenceMode": 1,
                    "billingCycleCount": 2
                  }
                ]
              }
            ]
          }
        ]""";

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
          await FlutterInappPurchase.instance.getProducts(productIds);
          expect(log, <Matcher>[
            isMethodCall(
              'getProducts',
              arguments: <String, dynamic>{
                'productIds': productIds,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          List<IAPItem> products =
              await FlutterInappPurchase.instance.getProducts(productIds);
          List<IAPItem> expected = (json.decode(result) as List)
              .map<IAPItem>(
                (product) => IAPItem.fromJSON(product as Map<String, dynamic>),
              )
              .toList();
          for (var i = 0; i < products.length; ++i) {
            var product = products[i];
            var expectedProduct = expected[i];
            expect(product.productId, expectedProduct.productId);
            expect(product.price, expectedProduct.price);
            expect(product.currency, expectedProduct.currency);
            expect(product.localizedPrice, expectedProduct.localizedPrice);
            expect(product.title, expectedProduct.title);
            expect(product.description, expectedProduct.description);
            expect(
                product.introductoryPrice, expectedProduct.introductoryPrice);
            expect(product.subscriptionPeriodNumberIOS,
                expectedProduct.subscriptionPeriodNumberIOS);
            expect(product.introductoryPricePaymentModeIOS,
                expectedProduct.introductoryPricePaymentModeIOS);
            expect(product.introductoryPriceNumberOfPeriodsIOS,
                expectedProduct.introductoryPriceNumberOfPeriodsIOS);
            expect(product.introductoryPriceSubscriptionPeriodIOS,
                expectedProduct.introductoryPriceSubscriptionPeriodIOS);
            expect(product.subscriptionPeriodAndroid,
                expectedProduct.subscriptionPeriodAndroid);
          }
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = []..add("testsku");

        final dynamic result = [
          {
            "productId": "com.cooni.point1000",
            "price": "120",
            "currency": "JPY",
            "localizedPrice": "¥120",
            "title": "1,000",
            "description": "1000 points 1000P",
            "introductoryPrice": "1001",
            "introductoryPricePaymentModeIOS": "1002",
            "introductoryPriceNumberOfPeriodsIOS": "1003",
            "introductoryPriceSubscriptionPeriodIOS": "1004",
            "subscriptionPeriodUnitIOS": "1",
            "subscriptionPeriodAndroid": "2",
            "subscriptionPeriodNumberIOS": "3",
            "introductoryPriceCyclesAndroid": 4,
            "introductoryPricePeriodAndroid": "5",
            "freeTrialPeriodAndroid": "6",
            "discounts": [
              {
                "identifier": "123",
                "type": "test",
                "numberOfPeriods": "3",
                "price": 100.toDouble(),
                "localizedPrice": "¥100",
                "paymentMode": "test",
                "subscriptionPeriod": "123"
              }
            ]
          }
        ];

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
          await FlutterInappPurchase.instance.getProducts(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItems',
              arguments: <String, dynamic>{
                'skus': skus,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          List<IAPItem> products =
              await FlutterInappPurchase.instance.getProducts(skus);
          List<IAPItem>? expected = result
              .map<IAPItem>(
                (product) => IAPItem.fromJSON(product as Map<String, dynamic>),
              )
              .toList();
          for (var i = 0; i < products.length; ++i) {
            var product = products[i];
            var expectedProduct = expected![i];
            expect(product.productId, expectedProduct.productId);
            expect(product.price, expectedProduct.price);
            expect(product.currency, expectedProduct.currency);
            expect(product.localizedPrice, expectedProduct.localizedPrice);
            expect(product.title, expectedProduct.title);
            expect(product.description, expectedProduct.description);
            expect(
                product.introductoryPrice, expectedProduct.introductoryPrice);
            expect(product.subscriptionPeriodNumberIOS,
                expectedProduct.subscriptionPeriodNumberIOS);
            expect(product.introductoryPricePaymentModeIOS,
                expectedProduct.introductoryPricePaymentModeIOS);
            expect(product.introductoryPriceNumberOfPeriodsIOS,
                expectedProduct.introductoryPriceNumberOfPeriodsIOS);
            expect(product.introductoryPriceSubscriptionPeriodIOS,
                expectedProduct.introductoryPriceSubscriptionPeriodIOS);
            expect(product.subscriptionPeriodAndroid,
                expectedProduct.subscriptionPeriodAndroid);
            // expect(product.introductoryPriceCyclesAndroid,
            //     expectedProduct.introductoryPriceCyclesAndroid);
            // expect(product.introductoryPricePeriodAndroid,
            //     expectedProduct.introductoryPricePeriodAndroid);
            // expect(product.freeTrialPeriodAndroid,
            //     expectedProduct.freeTrialPeriodAndroid);
          }
        });
      });
    });

    group('getSubscriptions', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> productIds = []..add("testsku");

        final dynamic result = """[
          {
            "productId": "com.cooni.point1000",
            "price": "120",
            "currency": "JPY",
            "localizedPrice": "¥120",
            "title": "1,000",
            "description": "1000 points 1000P",
            "introductoryPrice": "1001",
            "introductoryPricePaymentModeIOS": "1002",
            "introductoryPriceNumberOfPeriodsIOS": "1003",
            "introductoryPriceSubscriptionPeriodIOS": "1004",
            "subscriptionPeriodUnitIOS": "1",
            "subscriptionPeriodAndroid": "2",
            "subscriptionPeriodNumberIOS": "3",
            "introductoryPriceCyclesAndroid": 4,
            "introductoryPricePeriodAndroid": "5",
            "freeTrialPeriodAndroid": "6"
          }
        ]""";

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
          await FlutterInappPurchase.instance.getSubscriptions(productIds);
          expect(log, <Matcher>[
            isMethodCall(
              'getSubscriptions',
              arguments: <String, dynamic>{
                'productIds': productIds,
              },
            ),
          ]);
        });
        test('returns correct result', () async {
          List<IAPItem> products =
              await FlutterInappPurchase.instance.getSubscriptions(productIds);
          List<IAPItem> expected = (json.decode(result) as List)
              .map<IAPItem>(
                (product) => IAPItem.fromJSON(product as Map<String, dynamic>),
              )
              .toList();
          for (var i = 0; i < products.length; ++i) {
            var product = products[i];
            var expectedProduct = expected[i];
            expect(product.productId, expectedProduct.productId);
            expect(product.price, expectedProduct.price);
            expect(product.currency, expectedProduct.currency);
            expect(product.localizedPrice, expectedProduct.localizedPrice);
            expect(product.title, expectedProduct.title);
            expect(product.description, expectedProduct.description);
            expect(
                product.introductoryPrice, expectedProduct.introductoryPrice);
            expect(product.subscriptionPeriodNumberIOS,
                expectedProduct.subscriptionPeriodNumberIOS);
            expect(product.introductoryPricePaymentModeIOS,
                expectedProduct.introductoryPricePaymentModeIOS);
            expect(product.introductoryPriceNumberOfPeriodsIOS,
                expectedProduct.introductoryPriceNumberOfPeriodsIOS);
            expect(product.introductoryPriceSubscriptionPeriodIOS,
                expectedProduct.introductoryPriceSubscriptionPeriodIOS);
            expect(product.subscriptionPeriodAndroid,
                expectedProduct.subscriptionPeriodAndroid);
            // expect(product.introductoryPriceCyclesAndroid,
            //     expectedProduct.introductoryPriceCyclesAndroid);
            // expect(product.introductoryPricePeriodAndroid,
            //     expectedProduct.introductoryPricePeriodAndroid);
            // expect(product.freeTrialPeriodAndroid,
            //     expectedProduct.freeTrialPeriodAndroid);
          }
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        List<String> skus = []..add("testsku");

        final dynamic result = [
          {
            "productId": "com.cooni.point1000",
            "price": "120",
            "currency": "JPY",
            "localizedPrice": "¥120",
            "title": "1,000",
            "description": "1000 points 1000P",
            "introductoryPrice": "1001",
            "introductoryPricePaymentModeIOS": "1002",
            "introductoryPriceNumberOfPeriodsIOS": "1003",
            "introductoryPriceSubscriptionPeriodIOS": "1004",
            "subscriptionPeriodUnitIOS": "1",
            "subscriptionPeriodAndroid": "2",
            "subscriptionPeriodNumberIOS": "3",
            "introductoryPriceCyclesAndroid": 4,
            "introductoryPricePeriodAndroid": "5",
            "freeTrialPeriodAndroid": "6"
          }
        ];

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
          await FlutterInappPurchase.instance.getSubscriptions(skus);
          expect(log, <Matcher>[
            isMethodCall(
              'getItems',
              arguments: <String, dynamic>{
                'skus': skus,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          List<IAPItem> products =
              await FlutterInappPurchase.instance.getSubscriptions(skus);
          List<IAPItem>? expected = result
              .map<IAPItem>(
                (product) => IAPItem.fromJSON(product as Map<String, dynamic>),
              )
              .toList();
          for (var i = 0; i < products.length; ++i) {
            var product = products[i];
            var expectedProduct = expected![i];
            expect(product.productId, expectedProduct.productId);
            expect(product.price, expectedProduct.price);
            expect(product.currency, expectedProduct.currency);
            expect(product.localizedPrice, expectedProduct.localizedPrice);
            expect(product.title, expectedProduct.title);
            expect(product.description, expectedProduct.description);
            expect(
                product.introductoryPrice, expectedProduct.introductoryPrice);
            expect(product.subscriptionPeriodNumberIOS,
                expectedProduct.subscriptionPeriodNumberIOS);
            expect(product.introductoryPricePaymentModeIOS,
                expectedProduct.introductoryPricePaymentModeIOS);
            expect(product.introductoryPriceNumberOfPeriodsIOS,
                expectedProduct.introductoryPriceNumberOfPeriodsIOS);
            expect(product.introductoryPriceSubscriptionPeriodIOS,
                expectedProduct.introductoryPriceSubscriptionPeriodIOS);
            expect(product.subscriptionPeriodAndroid,
                expectedProduct.subscriptionPeriodAndroid);
            // expect(product.introductoryPriceCyclesAndroid,
            //     expectedProduct.introductoryPriceCyclesAndroid);
            // expect(product.introductoryPricePeriodAndroid,
            //     expectedProduct.introductoryPricePeriodAndroid);
            // expect(product.freeTrialPeriodAndroid,
            //     expectedProduct.freeTrialPeriodAndroid);
          }
        });
      });
    });

    group('getPurchaseHistory', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];

        final String resultInapp = """[{
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
          }]""";
        final String resultSubs = """[{
            "transactionDate":"1552824902000",
            "transactionId":"testSubsTransactionId",
            "productId":"com.cooni.point1000.subs",
            "transactionReceipt":"testSubsTransactionReciept",
            "purchaseToken":"testSubsPurchaseToken",
            "autoRenewingAndroid":true,
            "dataAndroid":"testSubsDataAndroid",
            "signatureAndroid":"testSubsSignatureAndroid",
            "originalTransactionDateIOS":"1552831136000",
            "originalTransactionIdentifierIOS":"testSubsOriginalTransactionIdentifierIOS"
          }]""";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            var m = methodCall.arguments as Map<dynamic, dynamic>;
            if (m['type'] == 'inapp') {
              return resultInapp;
            } else if (m['type'] == 'subs') {
              return resultSubs;
            }
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.getPurchaseHistory();
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

        test('returns correct result', () async {
          List<PurchasedItem>? actualList =
              await (FlutterInappPurchase.instance.getPurchaseHistory()) ?? [];
          List<PurchasedItem> expectList = ((json.decode(resultInapp) as List) +
                  (json.decode(resultSubs) as List))
              .map((item) => PurchasedItem.fromJSON(item))
              .toList();

          for (var i = 0; i < actualList.length; ++i) {
            PurchasedItem actual = actualList[i];
            PurchasedItem expected = expectList[i];

            expect(actual.transactionDate, expected.transactionDate);
            expect(actual.transactionId, expected.transactionId);
            expect(actual.productId, expected.productId);
            expect(actual.transactionReceipt, expected.transactionReceipt);
            expect(actual.purchaseToken, expected.purchaseToken);
            expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
            expect(actual.dataAndroid, expected.dataAndroid);
            expect(actual.signatureAndroid, expected.signatureAndroid);
            expect(actual.originalTransactionDateIOS,
                expected.originalTransactionDateIOS);
            expect(actual.originalTransactionIdentifierIOS,
                expected.originalTransactionIdentifierIOS);
          }
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];

        final dynamic result = [
          {
            "transactionDate": "1552824902000",
            "transactionId": "testTransactionId",
            "productId": "com.cooni.point1000",
            "transactionReceipt": "testTransactionReciept",
            "purchaseToken": "testPurchaseToken",
            "autoRenewingAndroid": true,
            "dataAndroid": "testDataAndroid",
            "signatureAndroid": "testSignatureAndroid",
            "originalTransactionDateIOS": "1552831136000",
            "originalTransactionIdentifierIOS":
                "testOriginalTransactionIdentifierIOS"
          },
          {
            "transactionDate": "1552824902000",
            "transactionId": "testSubsTransactionId",
            "productId": "com.cooni.point1000.subs",
            "transactionReceipt": "testSubsTransactionReciept",
            "purchaseToken": "testSubsPurchaseToken",
            "autoRenewingAndroid": true,
            "dataAndroid": "testSubsDataAndroid",
            "signatureAndroid": "testSubsSignatureAndroid",
            "originalTransactionDateIOS": "1552831136000",
            "originalTransactionIdentifierIOS":
                "testSubsOriginalTransactionIdentifierIOS"
          }
        ];

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
          await FlutterInappPurchase.instance.getPurchaseHistory();
          expect(log, <Matcher>[
            isMethodCall(
              'getAvailableItems',
              arguments: null,
            ),
          ]);
        });

        test('returns correct result', () async {
          List<PurchasedItem>? actualList =
              await (FlutterInappPurchase.instance.getPurchaseHistory()) ?? [];
          List<PurchasedItem>? expectList = result
              .map<PurchasedItem>((item) => PurchasedItem.fromJSON(item))
              .toList();

          for (var i = 0; i < actualList.length; ++i) {
            PurchasedItem actual = actualList[i];
            PurchasedItem expected = expectList![i];

            expect(actual.transactionDate, expected.transactionDate);
            expect(actual.transactionId, expected.transactionId);
            expect(actual.productId, expected.productId);
            expect(actual.transactionReceipt, expected.transactionReceipt);
            expect(actual.purchaseToken, expected.purchaseToken);
            expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
            expect(actual.dataAndroid, expected.dataAndroid);
            expect(actual.signatureAndroid, expected.signatureAndroid);
            expect(actual.originalTransactionDateIOS,
                expected.originalTransactionDateIOS);
            expect(actual.originalTransactionIdentifierIOS,
                expected.originalTransactionIdentifierIOS);
          }
        });
      });
    });

    group('getAvailablePurchases', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];

        final String resultInapp = """[{
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
          }]""";
        final String resultSubs = """[{
            "transactionDate":"1552824902000",
            "transactionId":"testSubsTransactionId",
            "productId":"com.cooni.point1000.subs",
            "transactionReceipt":"testSubsTransactionReciept",
            "purchaseToken":"testSubsPurchaseToken",
            "autoRenewingAndroid":true,
            "dataAndroid":"testSubsDataAndroid",
            "signatureAndroid":"testSubsSignatureAndroid",
            "originalTransactionDateIOS":"1552831136000",
            "originalTransactionIdentifierIOS":"testSubsOriginalTransactionIdentifierIOS"
          }]""";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            var m = methodCall.arguments as Map<dynamic, dynamic>;
            if (m['type'] == 'inapp') {
              return resultInapp;
            } else if (m['type'] == 'subs') {
              return resultSubs;
            }
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.getAvailablePurchases();
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

        test('returns correct result', () async {
          List<PurchasedItem>? actualList =
              await (FlutterInappPurchase.instance.getAvailablePurchases()) ??
                  [];
          List<PurchasedItem> expectList = ((json.decode(resultInapp) as List) +
                  (json.decode(resultSubs) as List))
              .map((item) => PurchasedItem.fromJSON(item))
              .toList();

          for (var i = 0; i < actualList.length; ++i) {
            PurchasedItem actual = actualList[i];
            PurchasedItem expected = expectList[i];

            expect(actual.transactionDate, expected.transactionDate);
            expect(actual.transactionId, expected.transactionId);
            expect(actual.productId, expected.productId);
            expect(actual.transactionReceipt, expected.transactionReceipt);
            expect(actual.purchaseToken, expected.purchaseToken);
            expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
            expect(actual.dataAndroid, expected.dataAndroid);
            expect(actual.signatureAndroid, expected.signatureAndroid);
            expect(actual.originalTransactionDateIOS,
                expected.originalTransactionDateIOS);
            expect(actual.originalTransactionIdentifierIOS,
                expected.originalTransactionIdentifierIOS);
          }
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];

        final dynamic result = [
          {
            "transactionDate": "1552824902000",
            "transactionId": "testTransactionId",
            "productId": "com.cooni.point1000",
            "transactionReceipt": "testTransactionReciept",
            "purchaseToken": "testPurchaseToken",
            "autoRenewingAndroid": true,
            "dataAndroid": "testDataAndroid",
            "signatureAndroid": "testSignatureAndroid",
            "originalTransactionDateIOS": "1552831136000",
            "originalTransactionIdentifierIOS":
                "testOriginalTransactionIdentifierIOS"
          },
          {
            "transactionDate": "1552824902000",
            "transactionId": "testSubsTransactionId",
            "productId": "com.cooni.point1000.subs",
            "transactionReceipt": "testSubsTransactionReciept",
            "purchaseToken": "testSubsPurchaseToken",
            "autoRenewingAndroid": true,
            "dataAndroid": "testSubsDataAndroid",
            "signatureAndroid": "testSubsSignatureAndroid",
            "originalTransactionDateIOS": "1552831136000",
            "originalTransactionIdentifierIOS":
                "testSubsOriginalTransactionIdentifierIOS"
          }
        ];

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
          await FlutterInappPurchase.instance.getAvailablePurchases();
          expect(log, <Matcher>[
            isMethodCall(
              'getAvailableItems',
              arguments: null,
            ),
          ]);
        });

        test('returns correct result', () async {
          List<PurchasedItem>? actualList =
              await (FlutterInappPurchase.instance.getAvailablePurchases()) ??
                  [];
          List<PurchasedItem>? expectList = result
              .map<PurchasedItem>((item) =>
                  PurchasedItem.fromJSON(item as Map<String, dynamic>))
              .toList();

          for (var i = 0; i < actualList.length; ++i) {
            PurchasedItem actual = actualList[i];
            PurchasedItem expected = expectList![i];

            expect(actual.transactionDate, expected.transactionDate);
            expect(actual.transactionId, expected.transactionId);
            expect(actual.productId, expected.productId);
            expect(actual.transactionReceipt, expected.transactionReceipt);
            expect(actual.purchaseToken, expected.purchaseToken);
            expect(actual.autoRenewingAndroid, expected.autoRenewingAndroid);
            expect(actual.dataAndroid, expected.dataAndroid);
            expect(actual.signatureAndroid, expected.signatureAndroid);
            expect(actual.originalTransactionDateIOS,
                expected.originalTransactionDateIOS);
            expect(actual.originalTransactionIdentifierIOS,
                expected.originalTransactionIdentifierIOS);
          }
        });
      });
    });

    group('requestPurchase', () {
      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        /*
        final dynamic result = {
          "transactionDate": "1552824902000",
          "transactionId": "testTransactionId",
          "productId": "com.cooni.point1000",
          "transactionReceipt": "testTransactionReciept",
          "purchaseToken": "testPurchaseToken",
          "autoRenewingAndroid": true,
          "dataAndroid": "testDataAndroid",
          "signatureAndroid": "testSignatureAndroid",
          "originalTransactionDateIOS": "1552831136000",
          "originalTransactionIdentifierIOS":
              "testOriginalTransactionIdentifierIOS"
        };
         */

        final String sku = "testsku";
        final String forUser = "testObfuscatedUser";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.requestPurchase(
            sku,
            obfuscatedAccountId: forUser,
          );
          expect(log, <Matcher>[
            isMethodCall(
              'buyProduct',
              arguments: <String, dynamic>{
                'sku': sku,
                'forUser': forUser,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          expect(
              await FlutterInappPurchase.instance.requestPurchase(sku), null);
        });
      });

      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        final String productId = "testsku";
        /*
        final dynamic result = {
          "transactionDate": "1552824902000",
          "transactionId": "testTransactionId",
          "productId": "com.cooni.point1000",
          "transactionReceipt": "testTransactionReciept",
          "purchaseToken": "testPurchaseToken",
          "autoRenewingAndroid": true,
          "dataAndroid": "testDataAndroid",
          "signatureAndroid": "testSignatureAndroid",
          "originalTransactionDateIOS": "1552831136000",
          "originalTransactionIdentifierIOS":
              "testOriginalTransactionIdentifierIOS"
        };
         */

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.requestPurchase(productId);
          expect(log, <Matcher>[
            isMethodCall(
              'buyItemByType',
              arguments: <String, dynamic>{
                'type': 'inapp',
                'productId': productId,
                'prorationMode': -1,
                'obfuscatedAccountId': null,
                'obfuscatedProfileId': null,
                'purchaseToken': null,
                'offerTokenIndex': null
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.requestPurchase(productId),
              null);
        });
      });
    });

    group('requestSubscription', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];

        final String productId = "testsku";
        /*
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
         */

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.requestSubscription(productId);
          expect(log, <Matcher>[
            isMethodCall(
              'buyItemByType',
              arguments: <String, dynamic>{
                'type': 'subs',
                'productId': productId,
                'prorationMode': -1,
                'obfuscatedAccountId': null,
                'obfuscatedProfileId': null,
                'purchaseToken': null,
                'offerTokenIndex': null
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          expect(
              await FlutterInappPurchase.instance
                  .requestSubscription(productId),
              null);
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        final String sku = "testsku";
        final String forUser = "testObfuscatedUser";
        /*
        final dynamic result = {
          "transactionDate": "1552824902000",
          "transactionId": "testTransactionId",
          "productId": "com.cooni.point1000",
          "transactionReceipt": "testTransactionReciept",
          "purchaseToken": "testPurchaseToken",
          "autoRenewingAndroid": true,
          "dataAndroid": "testDataAndroid",
          "signatureAndroid": "testSignatureAndroid",
          "originalTransactionDateIOS": "1552831136000",
          "originalTransactionIdentifierIOS":
              "testOriginalTransactionIdentifierIOS"
        };
         */

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.requestPurchase(
            sku,
            obfuscatedAccountId: forUser,
          );
          expect(log, <Matcher>[
            isMethodCall(
              'buyProduct',
              arguments: <String, dynamic>{
                'sku': sku,
                'forUser': forUser,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.requestSubscription(sku),
              null);
        });
      });
    });

    group('acknowledgePurchaseAndroid', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        final String token = "testToken";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(token);
          expect(log, <Matcher>[
            isMethodCall(
              'acknowledgePurchase',
              arguments: <String, dynamic>{
                'token': token,
              },
            ),
          ]);
        });

        test('returns correct result', () async {
          expect(
              await FlutterInappPurchase.instance
                  .acknowledgePurchaseAndroid(token),
              null);
        });
      });
    });

    group('consumePurchaseAndroid', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        final String token = "testToken";

        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.consumePurchaseAndroid(token);
          expect(log, <Matcher>[
            isMethodCall('consumeProduct', arguments: <String, dynamic>{
              'token': token,
            }),
          ]);
        });

        test('returns correct result', () async {
          expect(
              await FlutterInappPurchase.instance.consumePurchaseAndroid(token),
              null);
        });
      });
    });

    group('endConnection', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return "Billing client has ended.";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.finalize();
          expect(log, <Matcher>[
            isMethodCall('endConnection', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.finalize(),
              "Billing client has ended.");
        });
      });

      group('for iOS', () {
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.finalize(),
              "Billing client has ended.");
        });
      });
    });

    group('finishTransactionIOS', () {
      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          FlutterInappPurchase.channel
              .setMockMethodCallHandler((MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance
              .finishTransactionIOS('purchase_token_111');
          expect(log, <Matcher>[
            isMethodCall('finishTransaction', arguments: <String, dynamic>{
              'transactionIdentifier': 'purchase_token_111',
            }),
          ]);
        });

        test('returns correct result', () async {
          expect(
            await FlutterInappPurchase.instance
                .finishTransactionIOS('purchase_token_111'),
            null,
          );
        });
      });
    });
    group('getAppStoreInitiatedProducts', () {
      group('for Android', () {
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          expect(
              await FlutterInappPurchase.instance
                  .getAppStoreInitiatedProducts(),
              <IAPItem>[]);
        });
      });

      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];

        final dynamic result = [
          {
            "productId": "com.cooni.point1000",
            "price": "120",
            "currency": "JPY",
            "localizedPrice": "¥120",
            "title": "1,000",
            "description": "1000 points 1000P",
            "introductoryPrice": "1001",
            "introductoryPricePaymentModeIOS": "1002",
            "introductoryPriceNumberOfPeriodsIOS": "1003",
            "introductoryPriceSubscriptionPeriodIOS": "1004",
            "subscriptionPeriodUnitIOS": "1",
            "subscriptionPeriodAndroid": "2",
            "subscriptionPeriodNumberIOS": "3",
            "introductoryPriceCyclesAndroid": 4,
            "introductoryPricePeriodAndroid": "5",
            "freeTrialPeriodAndroid": "6"
          }
        ];
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
          await FlutterInappPurchase.instance.getAppStoreInitiatedProducts();
          expect(log, <Matcher>[
            isMethodCall('getAppStoreInitiatedProducts', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          List<IAPItem> products = await FlutterInappPurchase.instance
              .getAppStoreInitiatedProducts();
          List<IAPItem>? expected = result
              .map<IAPItem>(
                (product) => IAPItem.fromJSON(product as Map<String, dynamic>),
              )
              .toList();
          for (var i = 0; i < products.length; ++i) {
            var product = products[i];
            var expectedProduct = expected![i];
            expect(product.productId, expectedProduct.productId);
            expect(product.price, expectedProduct.price);
            expect(product.currency, expectedProduct.currency);
            expect(product.localizedPrice, expectedProduct.localizedPrice);
            expect(product.title, expectedProduct.title);
            expect(product.description, expectedProduct.description);
            expect(
                product.introductoryPrice, expectedProduct.introductoryPrice);
            expect(product.subscriptionPeriodNumberIOS,
                expectedProduct.subscriptionPeriodNumberIOS);
            expect(product.introductoryPricePaymentModeIOS,
                expectedProduct.introductoryPricePaymentModeIOS);
            expect(product.introductoryPriceNumberOfPeriodsIOS,
                expectedProduct.introductoryPriceNumberOfPeriodsIOS);
            expect(product.introductoryPriceSubscriptionPeriodIOS,
                expectedProduct.introductoryPriceSubscriptionPeriodIOS);
            // expect(product.subscriptionPeriodAndroid,
            //     expectedProduct.subscriptionPeriodAndroid);
            // expect(product.introductoryPriceCyclesAndroid,
            //     expectedProduct.introductoryPriceCyclesAndroid);
            // expect(product.introductoryPricePeriodAndroid,
            //     expectedProduct.introductoryPricePeriodAndroid);
            // expect(product.freeTrialPeriodAndroid,
            //     expectedProduct.freeTrialPeriodAndroid);
          }
        });
      });
    });
    group('checkSubscribed', () {
      // FIXME
      // This method can't be tested, because this method calls static methods internally.
      // To test, it needs to change static method to non-static method.
    });

    group('validateReceiptAndroid', () {
      setUp(() {
        FlutterInappPurchase(FlutterInappPurchase.private(
            FakePlatform(operatingSystem: "android")));
      });

      tearDown(() {
        FlutterInappPurchase.channel.setMethodCallHandler(null);
      });

      test('returns correct http request url, isSubscription is true',
          () async {
        final String packageName = "testpackege";
        final String productId = "testProductId";
        final String productToken = "testProductToken";
        final String accessToken = "testAccessToken";
        final String type = "subscriptions";
        final response = await FlutterInappPurchase.instance
            .validateReceiptAndroid(
                packageName: packageName,
                productId: productId,
                productToken: productToken,
                accessToken: accessToken,
                isSubscription: true);
        expect(response.request!.url.toString(),
            "https://www.googleapis.com/androidpublisher/v3/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken");
      });
      test('returns correct http request url, isSubscription is false',
          () async {
        final String packageName = "testpackege";
        final String productId = "testProductId";
        final String productToken = "testProductToken";
        final String accessToken = "testAccessToken";
        final String type = "products";
        final response = await FlutterInappPurchase.instance
            .validateReceiptAndroid(
                packageName: packageName,
                productId: productId,
                productToken: productToken,
                accessToken: accessToken,
                isSubscription: false);
        expect(response.request!.url.toString(),
            "https://www.googleapis.com/androidpublisher/v3/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken");
      });
    });

    group('validateReceiptIos', () {
      final receiptBody = {
        'receipt-data': 'purchasedItem.transactionReceipt',
        'password': 'apple_password'
      };

      setUp(() {
        FlutterInappPurchase(FlutterInappPurchase.private(
          FakePlatform(operatingSystem: "ios"),
        ));
      });

      tearDown(() {
        FlutterInappPurchase.channel.setMethodCallHandler(null);
      });

      test('returns correct http request url in sandbox', () async {
        final response = await FlutterInappPurchase.instance.validateReceiptIos(
          receiptBody: receiptBody,
          isTest: true,
        );

        expect(
          response.request!.url.toString(),
          "https://sandbox.itunes.apple.com/verifyReceipt",
        );
      });

      test('returns correct http request url in production', () async {
        final response = await FlutterInappPurchase.instance.validateReceiptIos(
          receiptBody: receiptBody,
          isTest: false,
        );

        expect(
          response.request!.url.toString(),
          "https://buy.itunes.apple.com/verifyReceipt",
        );
      });
    });
  });
}
