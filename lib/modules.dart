/// An item available for purchase from either the `Google Play Store` or `iOS AppStore`
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
  final String introductoryPricePaymentModeIOS;
  final String introductoryPriceNumberOfPeriodsIOS;
  final String introductoryPriceSubscriptionPeriodIOS;

  /// android only
  final String subscriptionPeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String introductoryPricePeriodAndroid;
  final String freeTrialPeriodAndroid;

  /// Create [IAPItem] from a Map that was previously JSON formatted
  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String,
        price = json['price'] as String,
        currency = json['currency'] as String,
        localizedPrice = json['localizedPrice'] as String,
        title = json['title'] as String,
        description = json['description'] as String,
        introductoryPrice = json['introductoryPrice'] as String,
        introductoryPricePaymentModeIOS =
            json['introductoryPricePaymentModeIOS'] as String,
        introductoryPriceNumberOfPeriodsIOS =
            json['introductoryPriceNumberOfPeriodsIOS'] as String,
        introductoryPriceSubscriptionPeriodIOS =
            json['introductoryPriceSubscriptionPeriodIOS'] as String,
        subscriptionPeriodNumberIOS =
            json['subscriptionPeriodNumberIOS'] as String,
        subscriptionPeriodUnitIOS = json['subscriptionPeriodUnitIOS'] as String,
        subscriptionPeriodAndroid = json['subscriptionPeriodAndroid'] as String,
        introductoryPriceCyclesAndroid =
            json['introductoryPriceCyclesAndroid'] as String,
        introductoryPricePeriodAndroid =
            json['introductoryPricePeriodAndroid'] as String,
        freeTrialPeriodAndroid = json['freeTrialPeriodAndroid'] as String;

  /// Return the contents of this class as a string
  @override
  String toString() {
    return 'productId: $productId, '
        'price: $price, '
        'currency: $currency, '
        'localizedPrice: $localizedPrice, '
        'title: $title, '
        'description: $description, '
        'introductoryPrice: $introductoryPrice, '
        'introductoryPricePaymentModeIOS: $introductoryPrice, '
        'subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS, '
        'subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS, '
        'introductoryPricePaymentModeIOS: $introductoryPricePaymentModeIOS, '
        'introductoryPriceNumberOfPeriodsIOS: $introductoryPriceNumberOfPeriodsIOS, '
        'introductoryPriceSubscriptionPeriodIOS: $introductoryPriceSubscriptionPeriodIOS, '
        'subscriptionPeriodAndroid: $subscriptionPeriodAndroid, '
        'introductoryPriceCyclesAndroid: $introductoryPriceCyclesAndroid, '
        'introductoryPricePeriodAndroid: $introductoryPricePeriodAndroid, '
        'freeTrialPeriodAndroid: $freeTrialPeriodAndroid, ';
  }
}

/// An item which was purchased from either the `Google Play Store` or `iOS AppStore`
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

  /// Create [PurchasedItem] from a Map that was previously JSON formatted
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

  /// This returns transaction dates in ISO 8601 format.
  @override
  String toString() {
    return 'transactionDate: ${transactionDate?.toIso8601String()}, '
        'transactionId: $transactionId, '
        'productId: $productId, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'dataAndroid: $dataAndroid, '
        'signatureAndroid: $signatureAndroid, '
        'originalTransactionDateIOS: ${originalTransactionDateIOS?.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS';
  }

  /// Coerce miliseconds since epoch in double, int, or String into DateTime format
  static DateTime _extractDate(dynamic timestamp) {
    if (timestamp == null) return null;

    int _toInt() => double.parse(timestamp.toString()).toInt();
    return DateTime.fromMillisecondsSinceEpoch(_toInt());
  }
}
