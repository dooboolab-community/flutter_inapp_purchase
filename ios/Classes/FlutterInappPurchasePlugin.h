#import <Flutter/Flutter.h>
#import <StoreKit/StoreKit.h>

@interface FlutterInappPurchasePlugin : NSObject<FlutterPlugin, SKProductsRequestDelegate, SKPaymentTransactionObserver>{
  SKProductsRequest *productsRequest;
  NSMutableArray *validProducts;
}
@end
