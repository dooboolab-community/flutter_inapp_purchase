class IAPItem {
  final String productId;
  final String price;
  final String currency;
  final String localizedPrice;
  final String title;
  final String description;
  final String introductoryPrice;

  /// ios only
  final String subscriptionPeriodNumberIOS;
  final String subscriptionPeriodUnitIOS;

  /// android only
  final String subscriptionPeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String introductoryPricePeriodAndroid;
  final String freeTrialPeriodAndroid;

  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String,
        price = json['price'] as String,
        currency = json['currency'] as String,
        localizedPrice = json['localizedPrice'] as String,
        title = json['title'] as String,
        description = json['description'] as String,
        introductoryPrice = json['introductoryPrice'] as String,
        subscriptionPeriodNumberIOS =
            json['subscriptionPeriodNumberIOS'] as String,
        subscriptionPeriodUnitIOS = json['subscriptionPeriodUnitIOS'] as String,
        subscriptionPeriodAndroid = json['subscriptionPeriodAndroid'] as String,
        introductoryPriceCyclesAndroid =
            json['introductoryPriceCyclesAndroid'] as String,
        introductoryPricePeriodAndroid =
            json['introductoryPricePeriodAndroid'] as String,
        freeTrialPeriodAndroid = json['freeTrialPeriodAndroid'] as String;

  @override
  String toString() {
    return 'productId: $productId, '
        'price: $price, '
        'currency: $currency, '
        'localizedPrice: $localizedPrice, '
        'title: $title, '
        'description: $title, '
        'introductoryPrice: $introductoryPrice, '
        'subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS, '
        'subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS, '
        'subscriptionPeriodAndroid: $subscriptionPeriodAndroid, '
        'introductoryPriceCyclesAndroid: $introductoryPriceCyclesAndroid, '
        'introductoryPricePeriodAndroid: $introductoryPricePeriodAndroid, '
        'freeTrialPeriodAndroid: $freeTrialPeriodAndroid, ';
  }
}

class PurchasedItem {
  final DateTime transactionDate;
  final String transactionId;
  final String productId;
  final String transactionReceipt;
  final String purchaseToken;

  // Android only
  final bool autoRenewingAndroid;
  final String dataAndroid;
  final String signatureAndroid;

  // iOS only
  final DateTime originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;

  PurchasedItem.fromJSON(Map<String, dynamic> json)
      : transactionDate = _extractDate(json['transactionDate']),
        transactionId = json['transactionId'] as String,
        productId = json['productId'] as String,
        transactionReceipt = json['transactionReceipt'] as String,
        purchaseToken = json['purchaseToken'] as String,
        autoRenewingAndroid = json['autoRenewingAndroid'] as bool,
        dataAndroid = json['dataAndroid'] as String,
        signatureAndroid = json['signatureAndroid'] as String,
        originalTransactionDateIOS =
            _extractDate(json['originalTransactionDateIOS']),
        originalTransactionIdentifierIOS =
            json['originalTransactionIdentifierIOS'] as String;

  @override
  String toString() {
    return 'transactionDate: ${transactionDate.toIso8601String()}, '
        'transactionId: $transactionId, '
        'productId: $productId, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'dataAndroid: $dataAndroid, '
        'signatureAndroid: $signatureAndroid, '
        'originalTransactionDateIOS: ${originalTransactionDateIOS.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS';
  }

  static DateTime _extractDate(dynamic timestamp) {
    if (timestamp == null) return null;

    int _toInt() => double.parse(timestamp.toString()).toInt();
    return DateTime.fromMillisecondsSinceEpoch(_toInt());
  }
}
