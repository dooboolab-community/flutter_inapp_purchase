import 'modules.dart';
import 'dart:convert';

List<IAPItem> extractItems(dynamic result) {
  List list = json.decode(result.toString());
  List<IAPItem> products = list
      .map<IAPItem>(
        (dynamic product) => IAPItem.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return products;
}

List<PurchasedItem>? extractPurchased(dynamic result) {
  List<PurchasedItem>? decoded = json
      .decode(result.toString())
      .map<PurchasedItem>(
        (dynamic product) =>
            PurchasedItem.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return decoded;
}

List<PurchaseResult>? extractResult(dynamic result) {
  List<PurchaseResult>? decoded = json
      .decode(result.toString())
      .map<PurchaseResult>(
        (dynamic product) =>
            PurchaseResult.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return decoded;
}

int periodToDays(String period) {
  var days = -1;
  if (period == 'P1W') {
    days = 7;
  } else if (period == 'P1M') {
    days = 30;
  } else if (period == 'P3M') {
    days = 90;
  } else if (period == 'P6M') {
    days = 180;
  } else if (period == 'P1Y') {
    days = 365;
  }
  return days;
}
