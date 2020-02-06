enum ResponseCodeAndroid {
  BILLING_RESPONSE_RESULT_OK,
  BILLING_RESPONSE_RESULT_USER_CANCELED,
  BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
  BILLING_RESPONSE_RESULT_ERROR,
  BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED,
  BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED,
  UNKNOWN,
}

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
  final String signatureAndroid;

  final String iconUrl;
  final String originalJson;
  final String originalPrice;

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
        freeTrialPeriodAndroid = json['freeTrialPeriodAndroid'] as String,
        signatureAndroid = json['signatureAndroid'] as String,
        iconUrl = json['iconUrl'] as String,
        originalJson = json['originalJson'] as String,
        originalPrice = json['originalJson'] as String;

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
        'freeTrialPeriodAndroid: $freeTrialPeriodAndroid, '
        'iconUrl: $iconUrl, '
        'originalJson: $originalJson, '
        'originalPrice: $originalPrice, '
    ;
  }
}

/// An item which was purchased from either the `Google Play Store` or `iOS AppStore`
class PurchasedItem {
  final String productId;
  final String transactionId;
  final DateTime transactionDate;
  final String transactionReceipt;
  final String purchaseToken;
  final String orderId;

  // Android only
  final String dataAndroid;
  final String signatureAndroid;
  final bool autoRenewingAndroid;
  final bool isAcknowledgedAndroid;
  final int purchaseStateAndroid;
  final String developerPayloadAndroid;
  final String originalJsonAndroid;

  // iOS only
  final DateTime originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;
  final TransactionState transactionStateIOS;

  /// Create [PurchasedItem] from a Map that was previously JSON formatted
  PurchasedItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String,
        transactionId = json['transactionId'] as String,
        transactionDate = _extractDate(json['transactionDate']),
        transactionReceipt = json['transactionReceipt'] as String,
        purchaseToken = json['purchaseToken'] as String,
        orderId = json['orderId'] as String,

        dataAndroid = json['dataAndroid'] as String,
        signatureAndroid = json['signatureAndroid'] as String,
        isAcknowledgedAndroid = json['isAcknowledgedAndroid'] as bool,
        autoRenewingAndroid = json['autoRenewingAndroid'] as bool,
        purchaseStateAndroid = json['purchaseStateAndroid'] as int,
        developerPayloadAndroid = json['developerPayloadAndroid'] as String,
        originalJsonAndroid = json['originalJsonAndroid'] as String,

        originalTransactionDateIOS =
            _extractDate(json['originalTransactionDateIOS']),
        originalTransactionIdentifierIOS =
            json['originalTransactionIdentifierIOS'] as String,
        transactionStateIOS =
            _decodeTransactionStateIOS(json['transactionStateIOS'] as int);

  /// This returns transaction dates in ISO 8601 format.
  @override
  String toString() {
    return 'productId: $productId, '
        'transactionId: $transactionId, '
        'transactionDate: ${transactionDate?.toIso8601String()}, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '
        'orderId: $orderId, '
        /// android specific
        'dataAndroid: $dataAndroid, '
        'signatureAndroid: $signatureAndroid, '
        'isAcknowledgedAndroid: $isAcknowledgedAndroid, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'purchaseStateAndroid: $purchaseStateAndroid, '
        'developerPayloadAndroid: $developerPayloadAndroid, '
        'originalJsonAndroid: $originalJsonAndroid, '
        /// ios specific
        'originalTransactionDateIOS: ${originalTransactionDateIOS?.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS, '
        'transactionStateIOS: $transactionStateIOS';
  }

  /// Coerce miliseconds since epoch in double, int, or String into DateTime format
  static DateTime _extractDate(dynamic timestamp) {
    if (timestamp == null) return null;

    int _toInt() => double.parse(timestamp.toString()).toInt();
    return DateTime.fromMillisecondsSinceEpoch(_toInt());
  }
}

class PurchaseResult {
  final int responseCode;
  final String debugMessage;
  final String code;
  final String message;

  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message
  });

  PurchaseResult.fromJSON(Map<String, dynamic> json)
      : responseCode = json['responseCode'] as int,
        debugMessage = json['debugMessage'] as String,
        code = json['code'] as String,
        message = json['message'] as String;

  Map<String, dynamic> toJson() => {
    "responseCode": responseCode ?? 0,
    "debugMessage": debugMessage ?? '',
    "code": code ?? '',
    "message": message ?? '',
  };

  @override
  String toString() {
    return 'responseCode: $responseCode, '
        'debugMessage: $debugMessage, '
        'code: $code, '
        'message: $message'
    ;
  }
}


class ConnectionResult {
  final bool connected;

  ConnectionResult({
    this.connected,
  });

  ConnectionResult.fromJSON(Map<String, dynamic> json)
      : connected = json['connected'] as bool;

  Map<String, dynamic> toJson() => {
    "connected": connected ?? false,
  };

  @override
  String toString() {
    return 'connected: $connected'
    ;
  }
}

/// See also https://developer.apple.com/documentation/storekit/skpaymenttransactionstate
enum TransactionState {
  /// A transaction that is being processed by the App Store.
  purchasing,

  /// A successfully processed transaction.
  purchased,

  /// A failed transaction.
  failed,

  /// A transaction that restores content previously purchased by the user.
  restored,

  /// A transaction that is in the queue, but its final status is pending external action such as Ask to Buy.
  deferred,
}

TransactionState _decodeTransactionStateIOS(int rawValue) {
  switch (rawValue) {
    case 0:
      return TransactionState.purchasing;
    case 1:
      return TransactionState.purchased;
    case 2:
      return TransactionState.failed;
    case 3:
      return TransactionState.restored;
    case 4:
      return TransactionState.deferred;
    default:
      return null;
  }
}
