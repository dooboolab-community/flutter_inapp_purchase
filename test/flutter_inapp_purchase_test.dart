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
  });
}
