#import <Flutter/Flutter.h>
#import <StoreKit/StoreKit.h>

@interface FlutterInappPlugin : NSObject<FlutterPlugin, SKProductsRequestDelegate, SKPaymentTransactionObserver>{
  SKProductsRequest *productsRequest;
  NSArray *validProducts;
}
@end
