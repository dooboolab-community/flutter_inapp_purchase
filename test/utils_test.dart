import 'package:flutter_inapp_purchase/utils.dart';
import 'package:flutter_test/flutter_test.dart';

enum _TestEnum { Hoge }

void main() {
  group('utils', () {
    test('EnumUtil.getValueString', () async {
      String value = EnumUtil.getValueString(_TestEnum.Hoge);
      expect(value, "Hoge");
    });
  });
}
