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
