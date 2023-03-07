## 5.4.0

- Fixed wrong casting in checkSubscribed method by @kleeb in https://github.com/dooboolab/flutter_inapp_purchase/pull/368
- Upgrade to billing 5.1 (reverse compatible) by @SamBergeron in https://github.com/dooboolab/flutter_inapp_purchase/pull/392

## 5.3.0

## What's Changed

- Refactor java to kotlin, add showInAppMessageAndroid by @offline-first in https://github.com/dooboolab/flutter_inapp_purchase/pull/365

## New Contributors

- @offline-first made their first contribution in https://github.com/dooboolab/flutter_inapp_purchase/pull/365

**Full Changelog**: https://github.com/dooboolab/flutter_inapp_purchase/compare/5.2.0...5.3.0

## 5.2.0

Bugfix #356

## 5.1.1

Run on UiThread and few others (#328)

- Related #272

- The main difference is a new MethodResultWrapper class that wraps both the result and the channel. onMethodCall() now immediately saves this wrapped result-channel to a field and only uses that later to set both the result and to send back info on the channel. I did this in both Google and Amazon but I can't test the Amazon one.

- Included the plugin registration differences.

- Midified suggested in one of the issues that initConnection, endConnection and consumeAllItems shouldn't be accessors. This is very much so, property accessors are not supposed to do work and have side effects, just return a value. Now three new functions are suggested and marked the old ones deprecated.

Fourth, EnumUtil.getValueString() is not really necessary, we have describeEnum() in the Flutter engine just for this purpose.

## 5.1.0

Upgrade android billing client to `4.0.0` (#326)

Remove `orderId` in `Purchase`

- This is duplicate of `transactionId`.

Support for Amazon devices with Google Play sideloaded (#313)

## 5.0.4

- Add iOS promo codes (#325)
- Use http client in validateReceiptIos (#322)
- Amazon `getPrice` directly withoiut formatting (#316)

## 5.0.3

- Fix plugin exception for `requestProductWithQuantityIOS` [#306](https://github.com/dooboolab/flutter_inapp_purchase/pull/306)

## 5.0.2

- Replaced obfuscatedAccountIdAndroid with obfuscatedAccountId in request purchase method [#299](https://github.com/dooboolab/flutter_inapp_purchase/pull/299)

## 5.0.1

- Add AndroidProrationMode values [#273](https://github.com/dooboolab/flutter_inapp_purchase/pull/273)

## 5.0.0

- Support null safety [#275](https://github.com/dooboolab/flutter_inapp_purchase/pull/275)

## 4.0.2

- The dart side requires "introductoryPriceCyclesAndroid" to be a int [#268](https://github.com/dooboolab/flutter_inapp_purchase/pull/268)

## 4.0.1

- `platform` dep version `>=2.0.0 <4.0.0`

## 4.0.0

- Support flutter v2 [#265](https://github.com/dooboolab/flutter_inapp_purchase/pull/265)

## 3.0.1

- Migrate to flutter embedding v2 [#240](https://github.com/dooboolab/flutter_inapp_purchase/pull/240)
- Expose android purchase state as enum [#243](https://github.com/dooboolab/flutter_inapp_purchase/pull/243)

## 3.0.0

- Upgrade android billing client to `2.1.0` from `3.0.0`.
- Removed `deveoperId` and `accountId` when requesting `purchase` or `subscription` in `android`.
- Added `obfuscatedAccountIdAndroid` and `obfuscatedProfileIdAndroid` when requesting `purchase` or `subscription` in `android`.
- Removed `developerPayload` in `android`.
- Added `purchaseTokenAndroid` as an optional parameter to `requestPurchase` and `requestSubscription`.

## 2.3.1

Republishing since sourcode seems not merged correctly.

## 2.3.0

- Bugfix IAPItem deserialization [#212](https://github.com/dooboolab/flutter_inapp_purchase/pull/212)
- Add introductoryPriceNumberIOS [#214](https://github.com/dooboolab/flutter_inapp_purchase/pull/214)
- Fix iOS promotional offers [#220](https://github.com/dooboolab/flutter_inapp_purchase/pull/220)

## 2.2.0

- Implement `endConnection` method to declaratively finish observer in iOS.
- Remove `addTransactionObserver` in IAPPromotionObserver.m for dup observer problems.
- Automatically startPromotionObserver in `initConnection` for iOS.

## 2.1.5

- Fix ios failed purchase handling problem in 11.4+ [#176](https://github.com/dooboolab/flutter_inapp_purchase/pull/176)

## 2.1.4

- Fix dart side expression warning [#169](https://github.com/dooboolab/flutter_inapp_purchase/pull/169).

## 2.1.3

- Fix wrong introductory price number of periods [#164](https://github.com/dooboolab/flutter_inapp_purchase/pull/164).

## 2.1.2

- Trigger purchaseUpdated callback when iap purchased [#165](https://github.com/dooboolab/flutter_inapp_purchase/pull/165).

## 2.1.1

- Renamed `finishTransactionIOS` argument `purchaseToken` to `transactionId`.

## 2.1.0

- `finishTransaction` parameter changes to `purchasedItem` from `purchaseToken`.
- Update android billing client to `2.1.0` from `2.0.3`.

## 2.0.5

- [bugfix] Fix double call of result reply on connection init [#126](https://github.com/dooboolab/flutter_inapp_purchase/pull/126)

## 2.0.4

- [bugfix] Fix plugin throws exceptions with flutter v1.10.7 beta [#117](https://github.com/dooboolab/flutter_inapp_purchase/pull/117)

## 2.0.3

- [bugfix] Decode response code for connection updates stream [#114](https://github.com/dooboolab/flutter_inapp_purchase/pull/114)
- [bugfix] Fix typo in `consumePurchase` [#115](https://github.com/dooboolab/flutter_inapp_purchase/pull/115)

## 2.0.2

- use ConnectionResult as type for connection stream, fix controller creation [#112](https://github.com/dooboolab/flutter_inapp_purchase/pull/112)

## 2.0.0+16

- Resolve [#106](https://github.com/dooboolab/flutter_inapp_purchase/issues/106) by not sending `result.error` to the listener. Created use `_conectionSubscription`.

## 2.0.0+15

- Fixed minor typo when generating string with `toString`. Resolve [#110](https://github.com/dooboolab/flutter_inapp_purchase/issues/110).

## 2.0.0+14

- Pass android exception to flutter side.

## 2.0.0+13

- Android receipt validation api upgrade to `v3`.

## 2.0.0+12

- Resolve [#102](https://github.com/dooboolab/flutter_inapp_purchase/issues/102). Fluter seems to only sends strings between platforms.

## 2.0.0+9

- Resolve [#101](https://github.com/dooboolab/flutter_inapp_purchase/issues/101).

## 2.0.0+8

- Resolve [#100](https://github.com/dooboolab/flutter_inapp_purchase/issues/100).

## 2.0.0+7

- Resolve [#99](https://github.com/dooboolab/flutter_inapp_purchase/issues/99).

## 2.0.0+6

- Send `purchase-error` with purchases returns null.

## 2.0.0+5

- Renamed invoked parameters non-platform specific.

## 2.0.0+4

- Add `deveoperId` and `accountId` when requesting `purchase` or `subscription` in `android`. Find out more in `requestPurchase` and `requestSubscription`.

## 2.0.0+3

- Correctly mock invoke method and return results [#94](https://github.com/dooboolab/flutter_inapp_purchase/pull/96)

## 2.0.0+2

- Seperate long `example` code to `example` readme.

## 2.0.0+1

- Properly set return type `PurchaseResult` of when finishing transaction.

## 2.0.0 :tada:

- Removed deprecated note in the `readme`.
- Make the previous tests work in `travis`.
- Documentation on `readme` for breaking features.
- Abstracts `finishTransaction`.
  - `acknowledgePurchaseAndroid`, `consumePurchaseAndroid`, `finishTransactionIOS`.

[Android]

- Completely remove prepare.
- Upgrade billingclient to 2.0.3 which is currently recent in Sep 15 2019.
- Remove [IInAppBillingService] binding since billingClient has its own functionalities.
- Add [DoobooUtils] and add `getBillingResponseData` that visualizes erorr codes better.
- `buyProduct` no more return asyn result. It rather relies on the `purchaseUpdatedListener`.
- Add feature method `acknowledgePurchaseAndroid`
  - Implement `acknowledgePurchaseAndroid`.
  - Renamed `consumePurchase` to `consumePurchaseAndroid` in dart side.
  - Update test codes.
- Renamed methods
  - `buyProduct` to `requestPurchase`.
  - `buySubscription` to `requestSubscription`.

[iOS]

- Implment features in new releases.
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

- Add `DEPRECATION` note. Please use [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## 0.9.+

- Breaking change. Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also migrate to Android X if they're using the original support library. [Android's Migrating to Android X Guide](https://developer.android.com/jetpack/androidx/migrate).

* Improved getPurchaseHistory's speed 44% faster [#68](https://github.com/dooboolab/flutter_inapp_purchase/pull/68).

## 0.8.+

- Fixed receipt validation param for `android`.
- Updated `http` package.
- Implemented new method `getAppStoreInitiatedProducts`.
  - Handling of iOS method `paymentQueue:shouldAddStorePayment:forProduct:`
  - Has no effect on Android.
- Fixed issue with method `buyProductWithoutFinishTransaction` for iOS, was not getting the productId.
- Fixed issue with `toString` method of class `IAPItem`, was printing incorrect values.
- Fixes for #44. Unsafe getting `originalJson` when restoring item and `Android`.
- Use dictionaryWithObjectsAndKeys in NSDictionary to fetch product values. This will prevent from NSInvalidArgumentException in ios which rarely occurs.
- Fixed wrong npe in `android` when `getAvailablePurchases`.

* Only parse `orderId` when exists in `Android` to prevent crashing.
* Add additional success purchase listener in `iOS`. Related [#54](https://github.com/dooboolab/flutter_inapp_purchase/issues/54)

## 0.7.1

- Implemented receiptValidation for both android and ios.
  - In Android, you need own backend to get your `accessToken`.

## 0.7.0

- Addition of Amazon In-App Purchases.

## 0.6.9

- Prevent nil element exception when getting products.

## 0.6.8

- Prevent nil exception in ios when fetching products.

## 0.6.7

- Fix broken images on pub.

## 0.6.6

- Added missing introductory fields in ios.

## 0.6.5

- convert dynamic objects to PurchasedItems.
- Fix return type for getAvailablePurchases().
- Fix ios null value if optional operator.

## 0.6.3

- Update readme.

## 0.6.2

- Fixed failing when there is no introductory price in ios.

## 0.6.1

- Fixed `checkSubscribed` that can interrupt billing lifecycle.

## 0.6.0

- Major code refactoring by lukepighetti. Unify PlatformException, cleanup new, DateTime instead of string.

## 0.5.9

- Fix getSubscription json encoding problem in `ios`.

## 0.5.8

- Avoid crashing on android caused by IllegalStateException.

## 0.5.7

- Avoid possible memory leak in android by deleting static declaration of activity and context.

## 0.5.6

- Few types fixed.

## 0.5.4

- Fixed error parsing IAPItem.

## 0.5.3

- Fixed error parsing purchaseHistory.

## 0.5.2

- Fix crashing on error.

## 0.5.1

- Give better error message on ios.

## 0.5.0

- Code migration.
- Support subscription period.
- There was parameter renaming in `0.5.0` to identify different parameters sent from the device. Please check the readme.

## 0.4.3

- Fixed subscription return types.

## 0.4.0

- Well formatted code.

## 0.3.3

- Code formatted
- Updated missing data types

## 0.3.1

- Upgraded readme for ease of usage.
- Enabled strong mode.

## 0.3.0

- Moved dynamic return type away and instead give `PurchasedItem`.

## 0.2.3

- Quickly fixed purchase bug out there in [issue](https://github.com/dooboolab/flutter_inapp_purchase/issues/2). Need much more improvement currently.

## 0.2.2

- Migrated packages from FlutterInApp to FlutterInAppPurchase because pub won't get it.

## 0.1.0

- Initial release of beta
- Moved code from [react-native-iap](https://github.com/dooboolab/react-native-iap)
