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
  final String price;
  final String title;
  final String currency;
  final String productId;
  final String localizedPrice;
  final String? description;
  final String? introductoryPrice;

  /// ios only
  final String? subscriptionPeriodUnitIOS;
  final String? subscriptionPeriodNumberIOS;
  final String? introductoryPriceNumberIOS;
  final String? introductoryPricePaymentModeIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final List<DiscountIOS>? discountsIOS;

  /// android only
  final String? introductoryPricePeriodAndroid;
  final int? introductoryPriceCyclesAndroid;
  final String? subscriptionPeriodAndroid;
  final String? freeTrialPeriodAndroid;
  final String? signatureAndroid;
  final double? originalPrice;
  final String? originalJson;
  final String? iconUrl;

  /// Create [IAPItem] from a Map that was previously JSON formatted
  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'],
        title = json['title'],
        price = json['price'],
        currency = json['currency'],
        localizedPrice = json['localizedPrice'],
        description = json['description'],
        introductoryPrice = json['introductoryPrice'],
        introductoryPricePaymentModeIOS =
            json['introductoryPricePaymentModeIOS'],
        introductoryPriceNumberOfPeriodsIOS =
            json['introductoryPriceNumberOfPeriodsIOS'],
        introductoryPriceSubscriptionPeriodIOS =
            json['introductoryPriceSubscriptionPeriodIOS'],
        introductoryPriceNumberIOS = json['introductoryPriceNumberIOS'],
        subscriptionPeriodNumberIOS = json['subscriptionPeriodNumberIOS'],
        subscriptionPeriodUnitIOS = json['subscriptionPeriodUnitIOS'],
        subscriptionPeriodAndroid = json['subscriptionPeriodAndroid'],
        introductoryPriceCyclesAndroid = json['introductoryPriceCyclesAndroid'],
        introductoryPricePeriodAndroid = json['introductoryPricePeriodAndroid'],
        freeTrialPeriodAndroid = json['freeTrialPeriodAndroid'],
        signatureAndroid = json['signatureAndroid'],
        iconUrl = json['iconUrl'],
        originalJson = json['originalJson'],
        originalPrice = json['originalPrice'],
        discountsIOS = _extractDiscountIOS(json['discounts']);

  /// wow, i find if i want to save a IAPItem, there is not "toJson" to cast it into String...
  /// i'm sorry to see that... so,
  ///
  /// you can cast a IAPItem to json(Map<String, dynamic>) via invoke this method.
  /// for example:
  /// String str =  convert.jsonEncode(item)
  ///
  /// and then get IAPItem from "str" above
  /// IAPItem item = IAPItem.fromJSON(convert.jsonDecode(str));
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['productId'] = this.productId;
    data['price'] = this.price;
    data['currency'] = this.currency;
    data['localizedPrice'] = this.localizedPrice;
    data['title'] = this.title;
    data['description'] = this.description;
    data['introductoryPrice'] = this.introductoryPrice;

    data['subscriptionPeriodNumberIOS'] = this.subscriptionPeriodNumberIOS;
    data['subscriptionPeriodUnitIOS'] = this.subscriptionPeriodUnitIOS;
    data['introductoryPricePaymentModeIOS'] =
        this.introductoryPricePaymentModeIOS;
    data['introductoryPriceNumberOfPeriodsIOS'] =
        this.introductoryPriceNumberOfPeriodsIOS;
    data['introductoryPriceSubscriptionPeriodIOS'] =
        this.introductoryPriceSubscriptionPeriodIOS;

    data['subscriptionPeriodAndroid'] = this.subscriptionPeriodAndroid;
    data['introductoryPriceCyclesAndroid'] =
        this.introductoryPriceCyclesAndroid;
    data['introductoryPricePeriodAndroid'] =
        this.introductoryPricePeriodAndroid;
    data['freeTrialPeriodAndroid'] = this.freeTrialPeriodAndroid;
    data['signatureAndroid'] = this.signatureAndroid;

    data['iconUrl'] = this.iconUrl;
    data['originalJson'] = this.originalJson;
    data['originalPrice'] = this.originalPrice;
    data['discounts'] = this.discountsIOS;
    return data;
  }

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
        'discounts: $discountsIOS, ';
  }

  static List<DiscountIOS>? _extractDiscountIOS(dynamic json) {
    List? list = json as List?;
    List<DiscountIOS>? discounts;

    if (list != null) {
      discounts = list
          .map<DiscountIOS>(
            (dynamic discount) =>
                DiscountIOS.fromJSON(discount as Map<String, dynamic>),
          )
          .toList();
    }

    return discounts;
  }
}

class DiscountIOS {
  String? type;
  double? price;
  String? identifier;
  String? paymentMode;
  String? localizedPrice;
  String? numberOfPeriods;
  String? subscriptionPeriod;

  /// Create [DiscountIOS] from a Map that was previously JSON formatted
  DiscountIOS.fromJSON(Map<String, dynamic> json)
      : type = json['type'],
        price = json['price'] as double?,
        identifier = json['identifier'],
        paymentMode = json['paymentMode'],
        localizedPrice = json['localizedPrice'],
        numberOfPeriods = json['numberOfPeriods'],
        subscriptionPeriod = json['subscriptionPeriod'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['identifier'] = this.identifier;
    data['type'] = this.type;
    data['numberOfPeriods'] = this.numberOfPeriods;
    data['price'] = this.price;
    data['localizedPrice'] = this.localizedPrice;
    data['paymentMode'] = this.paymentMode;
    data['subscriptionPeriod'] = this.subscriptionPeriod;
    return data;
  }

  /// Return the contents of this class as a string
  @override
  String toString() {
    return 'identifier: $identifier, '
        'type: $type, '
        'numberOfPeriods: $numberOfPeriods, '
        'price: $price, '
        'localizedPrice: $localizedPrice, '
        'paymentMode: $paymentMode, '
        'subscriptionPeriod: $subscriptionPeriod, ';
  }
}

/// An item which was purchased from either the `Google Play Store` or `iOS AppStore`

class PurchasedItem {
  final String productId;
  final DateTime transactionDate;
  final String transactionReceipt;

  /// transactionId is null just for getPurchaseHistory for android.
  final String? transactionId;

  // Android only
  final String? orderId;
  final String? purchaseToken;
  final String? signatureAndroid;
  final bool? autoRenewingAndroid;
  final bool? isAcknowledgedAndroid;
  final PurchaseState? purchaseStateAndroid;

  @deprecated
  String? get originalJsonAndroid => transactionReceipt;
  @deprecated
  String? get dataAndroid => transactionReceipt;

  // iOS only
  final DateTime? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final TransactionState? transactionStateIOS;

  /// Create [PurchasedItem] from a Map that was previously JSON formatted
  PurchasedItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'],
        transactionReceipt = json['transactionReceipt'],
        transactionDate = _extractDate(json['transactionDate'])!,
        transactionId = json['transactionId'],
        purchaseToken = json['purchaseToken'],
        orderId = json['orderId'],
        signatureAndroid = json['signatureAndroid'],
        isAcknowledgedAndroid = json['isAcknowledgedAndroid'],
        autoRenewingAndroid = json['autoRenewingAndroid'],
        purchaseStateAndroid =
            _decodePurchaseStateAndroid(json['purchaseStateAndroid']),
        originalTransactionDateIOS =
            _extractDate(json['originalTransactionDateIOS']),
        originalTransactionIdentifierIOS =
            json['originalTransactionIdentifierIOS'],
        transactionStateIOS =
            _decodeTransactionStateIOS(json['transactionStateIOS']);

  /// This returns transaction dates in ISO 8601 format.
  @override
  String toString() {
    return 'productId: $productId, '
        'transactionId: $transactionId, '
        'transactionDate: ${transactionDate.toIso8601String()}, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '
        'orderId: $orderId, '

        /// android specific
        'signatureAndroid: $signatureAndroid, '
        'isAcknowledgedAndroid: $isAcknowledgedAndroid, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'purchaseStateAndroid: $purchaseStateAndroid, '

        /// ios specific
        'originalTransactionDateIOS: ${originalTransactionDateIOS?.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS, '
        'transactionStateIOS: $transactionStateIOS';
  }

  /// Coerce miliseconds since epoch in double, int, or String into DateTime format
  static DateTime? _extractDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! int) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}

class PurchaseResult {
  final int? responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;

  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
  });

  PurchaseResult.fromJSON(Map<String, dynamic> json)
      : responseCode = json['responseCode'],
        debugMessage = json['debugMessage'],
        code = json['code'],
        message = json['message'];

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
        'message: $message';
  }
}

class ConnectionResult {
  final bool? connected;

  ConnectionResult({this.connected});

  ConnectionResult.fromJSON(Map<String, dynamic> json)
      : connected = json['connected'];

  Map<String, dynamic> toJson() => {
        "connected": connected ?? false,
      };

  @override
  String toString() {
    return 'connected: $connected';
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

TransactionState? _decodeTransactionStateIOS(int? rawValue) {
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

/// See also https://developer.android.com/reference/com/android/billingclient/api/Purchase.PurchaseState
enum PurchaseState {
  pending,

  purchased,

  unspecified,
}

PurchaseState? _decodePurchaseStateAndroid(int? rawValue) {
  switch (rawValue) {
    case 0:
      return PurchaseState.unspecified;
    case 1:
      return PurchaseState.purchased;
    case 2:
      return PurchaseState.pending;
    default:
      return null;
  }
}
