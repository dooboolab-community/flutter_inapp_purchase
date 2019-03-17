import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  group('FlutterInappPurchase', () {
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
  });
}
