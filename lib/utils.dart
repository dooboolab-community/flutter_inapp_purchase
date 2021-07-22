import 'modules.dart';

List<IAPItem> extractItems(List<dynamic> result) {
  List<IAPItem> products = result
      .map<IAPItem>((map) => IAPItem.fromJSON(Map<String, dynamic>.from(map)))
      .toList();

  return products;
}

List<PurchasedItem> extractPurchased(List<dynamic> result) {
  final purhcased = result
      .map<PurchasedItem>(
        (product) => PurchasedItem.fromJSON(Map<String, dynamic>.from(product)),
      )
      .toList();

  return purhcased;
}

class EnumUtil {
  /// return enum value
  ///
  /// example: enum Type {Hoge},
  /// String value = EnumUtil.getValueString(Type.Hoge);
  /// assert(value == "Hoge");
  static String getValueString(dynamic enumType) =>
      enumType.toString().split('.')[1];
}
