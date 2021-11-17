import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

enum _TestEnum { Hoge }

void main() {
  group('utils', () {
    test('EnumUtil.getValueString', () async {
      String value = describeEnum(_TestEnum.Hoge);
      expect(value, "Hoge");
    });
  });
}
