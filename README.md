# flutter_inapp_purchase

[![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase)
[![Flutter CI](https://github.com/dooboolab/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/dooboolab/flutter_inapp_purchase/actions/workflows/ci.yml)
[![Coverage Status](https://codecov.io/gh/dooboolab/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/dooboolab/flutter_inapp_purchase)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Flutter V2

This packages is compatible with flutter v2 from `4.0.0`. For those who use older version please use `< 4.0.0`.

## Sponsors

### 2023-09-23
Exciting news! Five years after developing this repository, we've secured an official sponsor. It feels like a ray of hope for a project that was on the brink of extinction. This gives me ample motivation to rejuvenate this project. I hope we can get more support so that we can collaborate with more individuals in the future. Thank you, <a href="https://namiml.com">NAMI</a>!

<a href="https://namiml.com"><img src="https://github.com/dooboolab-community/react-native-iap/assets/27461460/89d71f61-bb73-400a-83bd-fe0f96eb726e" width="200"/></a>

## Sun Rise :sunrise:

Since many one of you wanted me to keep working on this plugin in [#93](https://github.com/dooboolab/flutter_inapp_purchase/issues/93), I've decided to keep working on current project. I hope many one of you can help me maintain this. Thank you for all your supports in advance :tada:.

~~## Deprecated
I've been maintaining this plugin since there wasn't an official plugin out when I implemented it. I saw in `flutter` github [issue #9591](https://github.com/flutter/flutter/issues/9591) that many people have been waiting for this plugin for more than a year before I've thought of building one. However, there has been an official `Google` plugin rised today which is [in_app_purchase](https://pub.dev/packages/in_app_purchase). Please try to use an official one because you might want to get much prompt support from giant `Google`.
Also, thanks for all your supports that made me stubborn to work hard on this plugin. I've had great experience with all of you and hope we can meet someday with other projects.
I'll leave this project as live for those who need time. I'll also try to merge the new `PR`'s and publish to `pub` if there's any further work given to this repo.~~

## What this plugin do

This is an `In App Purchase` plugin for flutter. This project has been `forked` from [react-native-iap](https://github.com/dooboolab/react-native-iap). We are trying to share same experience of `in-app-purchase` in `flutter` as in `react-native`.
We will keep working on it as time goes by just like we did in `react-native-iap`.

`PR` is always welcomed.

## Breaking Changes

- Sunrise in `2.0.0` for highly requests from customers on discomfort in what's called an `official` plugin [in_app_purchase](https://pub.dev/packages/in_app_purchase).
- Migrated to Android X in `0.9.0`. Please check the [Migration Guide](#migration-guide).
- There was parameter renaming in `0.5.0` to identify different parameters sent from the device. Please check the readme.

## Migration Guide

To migrate to `0.9.0` you must migrate your Android app to Android X by following the [Migrating to AndroidX Guide](https://developer.android.com/jetpack/androidx/migrate).

## Getting Started

Follow the [Medium Blog](https://medium.com/@dooboolab/flutter-in-app-purchase-7a3fb9345e2a) for the configuration.

Follow the [Medium Blog](https://medium.com/bosc-tech-labs-private-limited/how-to-implement-subscriptions-in-app-purchase-in-flutter-7ce8906e608a) to add **subscriptions** in app purchase.

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).

## Methods

| Func                         |                                                                                     Param                                                                                      |        Return         | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :--------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| initConnection               |                                                                                                                                                                                |       `String`        | Prepare IAP module. Must be called on Android before any other purchase flow methods. In ios, it will simply call `canMakePayments` method and return value.                                                                                                                                                                                                                                                                                                             |
| getProducts                  |                                                                        `List<String>` Product IDs/skus                                                                         |    `List<IAPItem>`    | Get a list of products (consumable and non-consumable items, but not subscriptions). Note: On iOS versions earlier than 11.2 this method _will_ return subscriptions if they are included in your list of SKUs. This is because we cannot differentiate between IAP products and subscriptions prior to 11.2.                                                                                                                                                            |
| getSubscriptions             |                                                                      `List<String>` Subscription IDs/skus                                                                      |    `List<IAPItem>`    | Get a list of subscriptions. Note: On iOS this method has the same output as `getProducts`. Because iOS does not differentiate between IAP products and subscriptions.                                                                                                                                                                                                                                                                                                   |
| getPurchaseHistory           |                                                                                                                                                                                |    `List<IAPItem>`    | Gets an invetory of purchases made by the user regardless of consumption status (where possible)                                                                                                                                                                                                                                                                                                                                                                         |
| getAvailablePurchases        |                                                                                                                                                                                | `List<PurchasedItem>` | (aka restore purchase) Get all purchases made by the user (either non-consumable, or haven't been consumed yet)                                                                                                                                                                                                                                                                                                                                                          |
| getAppStoreInitiatedProducts |                                                                                                                                                                                |    `List<IAPItem>`    | If the user has initiated a purchase directly on the App Store, the products that the user is attempting to purchase will be returned here. (iOS only) Note: On iOS versions earlier than 11.0 this method will always return an empty list, as the functionality was introduced in v11.0. [See Apple Docs for more info](https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/2877502-paymentqueue) Always returns an empty list on Android. |
| requestSubscription          | `String` sku, `String` oldSkuAndroid?, `int` prorationModeAndroid?, `String` obfuscatedAccountIdAndroid?, `String` obfuscatedProfileIdAndroid?, `String` purchaseTokenAndroid? |         Null          | Create (request) a subscription to a sku. For upgrading/downgrading subscription on Android pass second parameter with current subscription ID, on iOS this is handled automatically by store. `purchaseUpdatedListener` will receive the result.                                                                                                                                                                                                                        |
| requestPurchase              |                               `String` sku, `String` obfuscatedAccountIdAndroid?, `String` obfuscatedProfileIdAndroid?, `String` purchaseToken?                                |         Null          | Request a purchase. `purchaseUpdatedListener` will receive the result.                                                                                                                                                                                                                                                                                                                                                                                                   |
| finishTransactionIOS         |                                                                         `String` purchaseTokenAndroid                                                                          |   `PurchaseResult`    | Send finishTransaction call to Apple IAP server. Call this function after receipt validation process                                                                                                                                                                                                                                                                                                                                                                     |
| acknowledgePurchaseAndroid   |                                                                             `String` purchaseToken                                                                             |   `PurchaseResult`    | Acknowledge a product (on Android) for `non-consumable` and `subscription` purchase. No-op on iOS.                                                                                                                                                                                                                                                                                                                                                                       |
| consumePurchaseAndroid       |                                                                             `String` purchaseToken                                                                             |   `PurchaseResult`    | Consume a product (on Android) for `consumable` purchase. No-op on iOS.                                                                                                                                                                                                                                                                                                                                                                                                  |
| finishTransaction            |                                                                 `String` purchaseToken, `bool` isConsumable? }                                                                 |   `PurchaseResult`    | Send finishTransaction call that abstracts all `acknowledgePurchaseAndroid`, `finishTransactionIOS`, `consumePurchaseAndroid` methods.                                                                                                                                                                                                                                                                                                                                   |
| endConnection                |                                                                                                                                                                                |       `String`        | End billing connection.                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| consumeAllItems              |                                                                                                                                                                                |       `String`        | Manually consume all items in android. Do NOT call if you have any non-consumables (one time purchase items). No-op on iOS.                                                                                                                                                                                                                                                                                                                                              |
| validateReceiptIos           |                                                                `Map<String,String>` receiptBody, `bool` isTest                                                                 |    `http.Response`    | Validate receipt for ios.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| validateReceiptAndroid       |                                  `String` packageName, `String` productId, `String` productToken, `String` accessToken, `bool` isSubscription                                  |    `http.Response`    | Validate receipt for android.                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| showPromoCodesIOS            |                                                                                                                                                                                |                       | Show redeem codes in iOS.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| showInAppMessageAndroid      |                                                                                                                                                                                |                       | Google Play will show users messaging during grace period and account hold once per day and provide them an opportunity to fix their payment without leaving the app                                                                                                                                                                                                                                                                                                                                                                                                                                          |

## Purchase flow in `flutter_inapp_purchase@2.0.0+

![purchase-flow-sequence](https://github.com/dooboolab/react-native-iap/blob/main/docs/react-native-iapv3.svg)

> When you've successfully received result from `purchaseUpdated` listener, you'll have to `verify` the purchase either by `acknowledgePurchaseAndroid`, `consumePurchaseAndroid`, `finishTransactionIOS` depending on the purchase types or platforms. You'll have to use `consumePurchaseAndroid` for `consumable` products and `android` and `acknowledgePurchaseAndroid` for `non-consumable` products either `subscription`. For `ios`, there is no differences in `verifying` purchases. You can just call `finishTransaction`. If you do not verify the purchase, it will be refunded within 3 days to users. We recommend you to `verifyReceipt` first before actually finishing transaction. Lastly, if you want to abstract three different methods into one, consider using `finishTransaction` method.

## Data Types

- IAPItem

  ```dart
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
  ```

- PurchasedItem

  ```dart
  final String productId;
  final String transactionId;
  final DateTime transactionDate;
  final String transactionReceipt;
  final String purchaseToken;

  // Android only
  final String dataAndroid;
  final String signatureAndroid;
  final bool autoRenewingAndroid;
  final bool isAcknowledgedAndroid;
  final int purchaseStateAndroid;

  // iOS only
  final DateTime originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;
  ```

## Install

Add `flutter_inapp_purchase` as a dependency in pubspec.yaml

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

## Configuring in app purchase

- Please refer to [Blog](https://medium.com/@dooboolab/react-native-in-app-purchase-121622d26b67).
- [Amazon Kindle Fire](KINDLE.md)

## Usage Guide

#### Android `connect` and `endConnection`

- You should start the billing service in android to use its funtionalities. We recommend you to use `initConnection` getter method in `initState()`. Note that this step is necessary in `ios` also from `flutter_inapp_purchase@2.0.0+` which will also register the `purchaseUpdated` and `purchaseError` `Stream`.

  ```dart
    /// start connection for android
    @override
    void initState() {
      super.initState();
      asyncInitState(); // async is not allowed on initState() directly
    }

    void asyncInitState() async {
      await FlutterInappPurchase.instance.initConnection;
    }
  ```

- You should end the billing service in android when you are done with it. Otherwise it will be keep running in background. We recommend to use this feature in `dispose()`.

- Additionally, we've added `connectionUpdated` stream just in case if you'd like to monitor the connection more thoroughly form `2.0.1`.

  ```
  _conectionSubscription = FlutterInappPurchase.connectionUpdated.listen((connected) {
    print('connected: $connected');
  });
  ```

  > You can see how you can use this in detail in `example` project.

  ```dart
    /// start connection for android
    @override
    void dispose() async{
      super.dispose();
      await FlutterInappPurchase.instance.endConnection;
    }
  ```

#### Get IAP items

```dart
void getItems () async {
  List<IAPItem> items = await FlutterInappPurchase.instance.getProducts(_productLists);
  for (var item in items) {
    print('${item.toString()}');
    this._items.add(item);
  }
}
```

#### Purchase Item

```dart
void purchase() {
  FlutterInappPurchase.instance.requestPurchase(item.productId);
}
```

#### Register listeners to receive purchase

```dart
StreamSubscription _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen((productItem) {
  print('purchase-updated: $productItem');
});

StreamSubscription _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen((purchaseError) {
  print('purchase-error: $purchaseError');
});
```

#### Remove listeners when ending connection

```dart
_purchaseUpdatedSubscription.cancel();
_purchaseUpdatedSubscription = null;
_purchaseErrorSubscription.cancel();
_purchaseErrorSubscription = null;
```

#### Receipt validation

From `0.7.1`, we support receipt validation. For Android, you need separate json file from the service account to get the `access_token` from `google-apis`, therefore it is impossible to implement serverless. You should have your own backend and get `access_token`. With `access_token` you can simply call `validateReceiptAndroid` method we implemented. Further reading is [here](https://stackoverflow.com/questions/35127086/android-inapp-purchase-receipt-validation-google-play?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).
Currently, serverless receipt validation is possible using `validateReceiptIos` method. The first parameter, you should pass `transactionReceipt` which returns after `requestPurchase`. The second parameter, you should pass whether this is `test` environment. If `true`, it will request to `sandbox` and `false` it will request to `production`.

```dart
validateReceipt() async {
  var receiptBody = {
    'receipt-data': purchased.transactionReceipt,
    'password': '******'
  };
  const result = await validateReceiptIos(receiptBody, false);
  console.log(result);
}
```

For further information, please refer to [guide](https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html).

#### App Store initiated purchases

When the user starts an in-app purchase in the App Store, the transaction continues in your app, the product will then be added to a list that you can access through the method `getAppStoreInitiatedProducts`. This means you can decide how and when to continue the transaction.
To continue the transaction simple use the standard purchase flow from this plugin.

```dart
void checkForAppStoreInitiatedProducts() async {
  List<IAPItem> appStoreProducts = await FlutterInappPurchase.getAppStoreInitiatedProducts(); // Get list of products
  if (appStoreProducts.length > 0) {
    _requestPurchase(appStoreProducts.last); // Buy last product in the list
  }
}
```

## Example

Direct to [example readme](example/README.md) which is just a `cp` from example project. You can test this in real example project.

## ProGuard

If you have enabled proguard you will need to add the following rules to your `proguard-rules.pro`

```
#In app Purchase
-keep class com.amazon.** {*;}
-keep class com.dooboolab.** { *; }
-keep class com.android.vending.billing.**
-dontwarn com.amazon.**
-keepattributes *Annotation*
```

## Q & A

#### Can I buy product right away skipping fetching products if I already know productId?

- You can in `Android` but not in `ios`. In `ios` you should always `fetchProducts` first. You can see more info [here](https://medium.com/ios-development-tips-and-tricks/working-with-ios-in-app-purchases-e4b55491479b).

#### How do I validate receipt in ios?

- Official doc is [here](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html).

#### How do I validate receipt in android?

- Offical doc is [here](https://developer.android.com/google/play/billing/billing_library_overview).
- I've developed this feature for other developers to contribute easily who are aware of these things. The doc says you can also get the `accessToken` via play console without any of your backend server. You can get this by following process.
  - Select your app > Services & APIs > "YOUR LICENSE KEY FOR THIS APPLICATION Base64-encoded RSA public key to include in your binary". [reference](https://stackoverflow.com/questions/27132443/how-to-find-my-google-play-services-android-base64-public-key).

#### Invalid productId in ios.

- Please try below and make sure you've done belows.
  - Steps
    1. Completed an effective "Agreements, Tax, and Banking."
    2. Setup sandbox testing account in "Users and Roles."
    3. Signed into iOS device with sandbox account.
    4. Set up three In-App Purchases with the following status:
       i. Ready to Submit
       ii. Missing Metadata
       iii. Waiting for Review
    5. Enable "In-App Purchase" in Xcode "Capabilities" and in Apple Developer -> "App ID" setting. Delete app / Restart device / Quit "store" related processes in Activity Monitor / Xcode Development Provisioning Profile -> Clean -> Build.

## Help Maintenance

I've been maintaining quite many repos these days and burning out slowly. If you could help me cheer up, buying me a cup of coffee will make my life really happy and get much energy out of it.

[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)
<a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
