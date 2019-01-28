## 0.8.+
* Fixed receipt validation param for `android`.
* Updated `http` package.
* Implemented new method `getAppStoreInitiatedProducts`.
  - Handling of iOS method `paymentQueue:shouldAddStorePayment:forProduct:`
  - Has no effect on Android.
* Fixed issue with method `buyProductWithoutFinishTransaction` for iOS, was not getting the productId.
* Fixed issue with `toString` method of class `IAPItem`, was printing incorrect values.
* Fixes for #44. Unsafe getting `originalJson` when restoring item and `Android`.
* Use dictionaryWithObjectsAndKeys in NSDictionary to fetch product values. This will prevent from NSInvalidArgumentException in ios which rarely occurs.
* Fixed wrong npe in `android` when `getAvailablePurchases`.
+ Only parse `orderId` when exists in `Android` to prevent crashing.
+ Add additional success purchase listener in `iOS`. Related [#54](https://github.com/dooboolab/flutter_inapp_purchase/issues/54)

## 0.7.1
* Implemented receiptValidation for both android and ios.
  - In Android, you need own backend to get your `accessToken`.

## 0.7.0
* Addition of Amazon In-App Purchases.

## 0.6.9
* Prevent nil element exception when getting products.

## 0.6.8
* Prevent nil exception in ios when fetching products.

## 0.6.7
* Fix broken images on pub.

## 0.6.6
* Added missing introductory fields in ios.

## 0.6.5
* convert dynamic objects to PurchasedItems.
* Fix return type for getAvailablePurchases().
* Fix ios null value if optional operator.

## 0.6.3
* Update readme.

## 0.6.2
* Fixed failing when there is no introductory price in ios.

## 0.6.1
* Fixed `checkSubscribed` that can interrupt billing lifecycle.

## 0.6.0
* Major code refactoring by  lukepighetti. Unify PlatformException, cleanup new, DateTime instead of string.

## 0.5.9
* Fix getSubscription json encoding problem in `ios`.

## 0.5.8
* Avoid crashing on android caused by IllegalStateException.

## 0.5.7
* Avoid possible memory leak in android by deleting static declaration of activity and context.

## 0.5.6
* Few types fixed.

## 0.5.4
* Fixed error parsing IAPItem.

## 0.5.3
* Fixed error parsing purchaseHistory.

## 0.5.2
* Fix crashing on error.

## 0.5.1
* Give better error message on ios.

## 0.5.0
* Code migration.
* Support subscription period.
* There was parameter renaming in `0.5.0` to identify different parameters sent from the device. Please check the readme.

## 0.4.3
* Fixed subscription return types.

## 0.4.0
* Well formatted code.

## 0.3.3
* Code formatted
* Updated missing data types

## 0.3.1
* Upgraded readme for ease of usage.
* Enabled strong mode.

## 0.3.0
* Moved dynamic return type away and instead give `PurchasedItem`.

## 0.2.3
* Quickly fixed purchase bug out there in [issue](https://github.com/dooboolab/flutter_inapp_purchase/issues/2). Need much more improvement currently.

## 0.2.2
* Migrated packages from FlutterInApp to FlutterInAppPurchase because pub won't get it.

## 0.1.0

* Initial release of beta
* Moved code from [react-native-iap](https://github.com/dooboolab/react-native-iap)
