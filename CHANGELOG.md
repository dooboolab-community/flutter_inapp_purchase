## 2.0.4
+ [bugfix] Fix plugin throws exceptions with flutter v1.10.7 beta [#117](https://github.com/dooboolab/flutter_inapp_purchase/pull/117)
## 2.0.3
+ [bugfix] Decode response code for connection updates stream [#114](https://github.com/dooboolab/flutter_inapp_purchase/pull/114)
+ [bugfix] Fix typo in `consumePurchase` [#115](https://github.com/dooboolab/flutter_inapp_purchase/pull/115)
## 2.0.2
* use ConnectionResult as type for connection stream, fix controller creation [#112](https://github.com/dooboolab/flutter_inapp_purchase/pull/112)
## 2.0.0+16
* Resolve [#106](https://github.com/dooboolab/flutter_inapp_purchase/issues/106) by not sending `result.error` to the listener. Created use `_conectionSubscription`.
## 2.0.0+15
* Fixed minor typo when generating string with `toString`. Resolve [#110](https://github.com/dooboolab/flutter_inapp_purchase/issues/110).
## 2.0.0+14
* Pass android exception to flutter side.
## 2.0.0+13
* Android receipt validation api upgrade to `v3`.
## 2.0.0+12
* Resolve [#102](https://github.com/dooboolab/flutter_inapp_purchase/issues/102). Fluter seems to only sends strings between platforms.
## 2.0.0+9
* Resolve [#101](https://github.com/dooboolab/flutter_inapp_purchase/issues/101).
## 2.0.0+8
* Resolve [#100](https://github.com/dooboolab/flutter_inapp_purchase/issues/100).
## 2.0.0+7
* Resolve [#99](https://github.com/dooboolab/flutter_inapp_purchase/issues/99).
## 2.0.0+6
* Send `purchase-error` with purchases returns null.
## 2.0.0+5
* Renamed invoked parameters non-platform specific.
## 2.0.0+4
* Add `deveoperId` and `accountId` when requesting `purchase` or `subscription` in `android`. Find out more in `requestPurchase` and `requestSubscription`.

## 2.0.0+3
* Correctly mock invoke method and return results [#94](https://github.com/dooboolab/flutter_inapp_purchase/pull/96)

## 2.0.0+2
* Seperate long `example` code to `example` readme.

## 2.0.0+1
* Properly set return type `PurchaseResult` of when finishing transaction.

## 2.0.0 :tada:
* Removed deprecated note in the `readme`.
* Make the previous tests work in `travis`.
* Documentation on `readme` for breaking features.
* Abstracts `finishTransaction`.
  - `acknowledgePurchaseAndroid`, `consumePurchaseAndroid`, `finishTransactionIOS`.

[Android]
* Completely remove prepare.
* Upgrade billingclient to 2.0.3 which is currently recent in Sep 15 2019.
* Remove [IInAppBillingService] binding since billingClient has its own functionalities.
* Add [DoobooUtils] and add `getBillingResponseData` that visualizes erorr codes better.
* `buyProduct` no more return asyn result. It rather relies on the `purchaseUpdatedListener`.
* Add feature method `acknowledgePurchaseAndroid` 
   - Implement `acknowledgePurchaseAndroid`.
   - Renamed `consumePurchase` to `consumePurchaseAndroid` in dart side.
   - Update test codes.
* Renamed methods
   - `buyProduct` to `requestPurchase`.
   - `buySubscription` to `requestSubscription`.

[iOS]
* Implment features in new releases.
   - enforce to `finishTransaction` after purchases.
   - Work with `purchaseUpdated` and `purchaseError` listener as in android.
   - Feature set from `react-native-iap v3`.
   - Should call finish transaction in every purchase request.
   - Add `IAPPromotionObserver` cocoa touch file
   - Convert dic to json string before invoking purchase-updated
   - Add `getPromotedProductIOS` and `requestPromotedProductIOS` methods
   - Implement clearTransaction for ios
   - Include `purchasePromoted` stream that listens to `iap-promoted-product`.

## 1.0.0
+ Add `DEPRECATION` note. Please use [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## 0.9.+
* Breaking change. Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also migrate to Android X if they're using the original support library. [Android's Migrating to Android X Guide](https://developer.android.com/jetpack/androidx/migrate).
+ Improved getPurchaseHistory's speed 44% faster [#68](https://github.com/dooboolab/flutter_inapp_purchase/pull/68).

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
