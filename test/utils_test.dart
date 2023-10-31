import 'package:flutter_test/flutter_test.dart';

enum _TestEnum { Hoge }

void main() {
  group('utils', () {
    test('EnumUtil.getValueString', () async {
      String value = _TestEnum.Hoge.name;
      expect(value, "Hoge");
    });
  });
}
