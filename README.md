# flutter_inapp_purchase
<p align="left">
  <a href="https://pub.dartlang.org/packages/flutter_inapp_purchase"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square"></a>
</p>

In App Purchase plugin for flutter. This project has been `forked` from [react-native-iap](https://github.com/dooboolab/react-native-iap). We are trying to share same experience of `in-app-purchase` in `flutter` as in `react-native`.
We will keep working on it as time goes by just like we did in `react-native-iap`.

`PR` is always welcomed.

## Breaking Changes
* There was parameter renaming in `0.5.0` to identify different parameters sent from the device. Please check the readme.

## Getting Started
Follow the [Medium Blog](https://medium.com/@dooboolab/flutter-in-app-purchase-7a3fb9345e2a) for the configuration.

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).


## Methods
| Func  | Param  | Return | Description |
| :------------ |:---------------:| :---------------:| :-----|
| ~prepare~ |  | `String` | *Deprecated* Use initConnection instead. |
| initConnection |  | `String` | Prepare IAP module. Must be called on Android before any other purchase flow methods. In ios, it will simply call `canMakePayments` method and return value.|
| getProducts | `List<String>` Product IDs/skus | `List<IAPItem>` | Get a list of products (consumable and non-consumable items, but not subscriptions). Note: On iOS versions earlier than 11.2 this method _will_ return subscriptions if they are included in your list of SKUs. This is because we cannot differentiate between IAP products and subscriptions prior to 11.2.  |
| getSubscriptions | `List<String>` Subscription IDs/skus | `List<IAPItem>` | Get a list of subscriptions. Note: On iOS  this method has the same output as `getProducts`. Because iOS does not differentiate between IAP products and subscriptions.  |
| getPurchaseHistory | | `List<IAPItem>` | Gets an invetory of purchases made by the user regardless of consumption status (where possible) |
| getAvailablePurchases | | `List<PurchasedItem>` | (aka restore purchase) Get all purchases made by the user (either non-consumable, or haven't been consumed yet)
| getAppStoreInitiatedProducts | | `List<IAPItem>` | If the user has initiated a purchase directly on the App Store, the products that the user is attempting to purchase will be returned here. (iOS only) Note: On iOS versions earlier than 11.0 this method will always return an empty list, as the functionality was introduced in v11.0. [See Apple Docs for more info](https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/2877502-paymentqueue) Always returns an empty list on Android.
| buySubscription | `string` Subscription ID/sku, `string` Old Subscription ID/sku (on Android) | `PurchasedItem` | Create (buy) a subscription to a sku. For upgrading/downgrading subscription on Android pass second parameter with current subscription ID, on iOS this is handled automatically by store. |
| buyProduct | `string` Product ID/sku | `PurchasedItem` | Buy a product |
| ~~buyProductWithoutFinishTransaction~~ | `string` Product ID/sku | `PurchasedItem` | Buy a product without finish transaction call (iOS only) |
| finishTransaction | `void` | `String` | Send finishTransaction call to Apple IAP server. Call this function after receipt validation process |
| consumePurchase | `String` Purchase token | `String` | Consume a product (on Android.) No-op on iOS. |
| endConnection | | `String` | End billing connection (on Android.) No-op on iOS. |
| consumeAllItems | | `String` | Manually consume all items in android. Do NOT call if you have any non-consumables (one time purchase items). No-op on iOS. |
| validateReceiptIos | `Map<String,String>` receiptBody, `bool` isTest | `http.Response` | Validate receipt for ios. |
| validateReceiptAndroid | `String` packageName, `String` productId, `String` productToken, `String` accessToken, `bool` isSubscription | `http.Response` | Validate receipt for android. |


## Data Types
* IAPItem
  ```dart
  final String productId;
  final String price;
  final String currency;
  final String type;
  final String localizedPrice;
  final String title;
  final String description;
  final String introductoryPrice;
  /// ios only
  final String introductoryPricePaymentModeIOS;
  final String introductoryPriceNumberOfPeriodsIOS;
  final String introductoryPriceSubscriptionPeriodIOS;
  final String subscriptionPeriodNumberIOS;
  final String subscriptionPeriodUnitIOS;
  /// android only
  final String subscriptionPeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String introductoryPricePeriodAndroid;
  final String freeTrialPeriodAndroid;
  ```

* PurchasedItem
  ```dart
  final dynamic transactionDate;
  final String transactionId;
  final String productId;
  final String transactionReceipt;
  // Android only
  final String purchaseToken;
  final bool autoRenewingAndroid;
  final String dataAndroid;
  final String signatureAndroid;
  // iOS only
  final dynamic originalTransactionDateIOS;
  final String originalTransactionIdentifierIOS;
  ```


## Install
Add ```flutter_inapp_purchase``` as a dependency in pubspec.yaml

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).


## Configuring in app purchase
- Please refer to [Blog](https://medium.com/@dooboolab/react-native-in-app-purchase-121622d26b67).
- [Amazon Kindle Fire](KINDLE.md)


## Usage Guide
#### Android `connect` and `endConnection`
* You should start the billing service in android to use its funtionalities. We recommend you to use `initConnection` getter method in `initState()`. 
  ```dart
    /// start connection for android
    @override
    void initState() {
      super.initState();
      asyncInitState(); // async is not allowed on initState() directly
    }

    void asyncInitState() async {
      await FlutterInappPurchase.initConnection;
    }
  ```
* You should end the billing service in android when you are done with it. Otherwise it will be keep running in background. We recommend to use this feature in `dispose()`.
  ```
    /// start connection for android
    @override
    void dispose() async{
      super.dispose();
      await FlutterInappPurchase.endConnection;
    }
  ```
#### Get IAP items
  ```dart
  void getItems () async {
    List<IAPItem> items = await FlutterInappPurchase.getProducts(_productLists);
    for (var item in items) {
      print('${item.toString()}');
      this._items.add(item);
    }
  }
  ```

#### Purchase Item
  ```dart
  void purchase() async {
    PurchasedItem purchased = await FlutterInappPurchase.buyProduct(item.productId);
    print('purcuased - ${purchased.toString()}');
  }
  ```

#### Receipt validation
From `0.7.1`, we support receipt validation. For Android, you need separate json file from the service account to get the `access_token` from `google-apis`, therefore it is impossible to implement serverless. You should have your own backend and get `access_token`. With `access_token` you can simply call `validateReceiptAndroid` method we implemented. Further reading is [here](https://stackoverflow.com/questions/35127086/android-inapp-purchase-receipt-validation-google-play?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).
Currently, serverless receipt validation is possible using `validateReceiptIos` method. The first parameter, you should pass `transactionReceipt` which returns after `buyProduct`. The second parameter, you should pass whether this is `test` environment. If `true`, it will request to `sandbox` and `false` it will request to `production`.

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
    _buyProduct(appStoreProducts.last); // Buy last product in the list
  }
}
```


## Example
Below code is just a `cp` from example project. You can test this in real example project.
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String>_productLists = Platform.isAndroid
      ? [
    'android.test.purchased',
    'point_1000',
    '5000_point',
    'android.test.canceled',
  ]
      : ['com.cooni.point1000','com.cooni.point5000'];

  String _platformVersion = 'Unknown';
  List<IAPItem> _items = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterInappPurchase.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // initConnection
    var result = await FlutterInappPurchase.initConnection;
    print ('result: $result');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // refresh items for android
    String msg = await FlutterInappPurchase.consumeAllItems;
    print('consumeAllItems: $msg');
  }

  Future<Null> _buyProduct(IAPItem item) async {
    try {
      PurchasedItem purchased= await FlutterInappPurchase.buyProduct(item.productId);
      print('purcuased - ${purchased.toString()}');
    } catch (error) {
      print('$error');
    }
  }

  Future<Null> _getProduct() async {
    List<IAPItem> items = await FlutterInappPurchase.getProducts(_productLists);
    for (var item in items) {
      print('${item.toString()}');
      this._items.add(item);
    }

    setState(() {
      this._items = items;
    });
  }

  _renderInapps() {
    List<Widget> widgets = this._items.map((item) => Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 5.0),
              child: Text(
                item.toString(),
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
              ),
            ),
            FlatButton(
              color: Colors.orange,
              onPressed: () {
                this._buyProduct(item);
              },
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 48.0,
                      alignment: Alignment(-1.0, 0.0),
                      child: Text('Buy Item'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )).toList();
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Inapp Plugin by dooboolab'),
        ),
        body:
        Container(
          padding: EdgeInsets.all(10.0),
          child: ListView(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      'Running on: $_platformVersion\n',
                      style: TextStyle(
                          fontSize: 18.0
                      ),
                    ),
                  ),
                  Container(
                    height: 60.0,
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 15.0),
                              child: FlatButton(
                                color: Colors.green,
                                padding: EdgeInsets.all(0.0),
                                onPressed: () async {
                                  await FlutterInappPurchase.initConnection;
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                                  alignment: Alignment(0.0, 0.0),
                                  child: Text(
                                    'Connect Billing',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FlatButton(
                              color: Colors.green,
                              padding: EdgeInsets.all(0.0),
                              onPressed: () {
                                this._getProduct();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                alignment: Alignment(0.0, 0.0),
                                child: Text(
                                  'Get Items',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15.0),
                              child: FlatButton(
                                color: Colors.green,
                                padding: EdgeInsets.all(0.0),
                                onPressed: () async {
                                  await FlutterInappPurchase.endConnection;
                                  setState(() {
                                    this._items = [];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                                  alignment: Alignment(0.0, 0.0),
                                  child: Text(
                                    'End Connection',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: this._renderInapps(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## ProGuard
If you have eneabled proguard you will need to add the following rules to your `proguard-rules.pro`

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
  * Select your app > Services & APIs > "YOUR LICENSE KEY FOR THIS APPLICATION Base64-encoded RSA public key to include in your binary". [reference](https://stackoverflow.com/questions/27132443/how-to-find-my-google-play-services-android-base64-public-key).

#### Invalid productId in ios.
- Please try below and make sure you've done belows.
  - Steps
    1. Completed an effective "Agreements, Tax, and Banking."
    2. Setup sandbox testing account in "Users and Roles."
    3. Signed into iOS device with sandbox account.
    3. Set up three In-App Purchases with the following status:
       i. Ready to Submit
       ii. Missing Metadata
       iii. Waiting for Review
    4. Enable "In-App Purchase" in Xcode "Capabilities" and in Apple Developer -> "App ID" setting. Delete app / Restart device / Quit "store" related processes in Activity Monitor / Xcode Development Provisioning Profile -> Clean -> Build.

## Help Maintenance
I've been maintaining quite many repos these days and burning out slowly. If you could help me cheer up, buying me a cup of coffee will make my life really happy and get much energy out of it.
<br/><a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
