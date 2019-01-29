#import "FlutterInappPurchasePlugin.h"

@interface FlutterInappPurchasePlugin() {
    BOOL autoReceiptConform;
    SKPaymentTransaction *currentTransaction;
    FlutterResult flutterResult;
}

@property (atomic, retain) NSMutableDictionary<NSValue*, FlutterResult>* fetchProducts;
@property (atomic, retain) NSMutableDictionary<SKPayment*, FlutterResult>* requestedPayments;
@property (atomic, retain) NSArray<SKProduct*>* products;
@property (atomic, retain) NSMutableArray<SKProduct*>* appStoreInitiatedProducts;
@property (atomic, retain) NSMutableSet<NSString*>* purchases;
@property (nonatomic, retain) FlutterMethodChannel* channel;

@end

@implementation FlutterInappPurchasePlugin

@synthesize fetchProducts;
@synthesize requestedPayments;
@synthesize products;
@synthesize appStoreInitiatedProducts;
@synthesize purchases;
@synthesize channel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterInappPurchasePlugin* instance = [[FlutterInappPurchasePlugin alloc] init];
    instance.channel = [FlutterMethodChannel
                        methodChannelWithName:@"flutter_inapp"
                        binaryMessenger:[registrar messenger]];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
    self = [super init];
    self.fetchProducts = [[NSMutableDictionary alloc] init];
    self.requestedPayments = [[NSMutableDictionary alloc] init];
    self.products = [[NSArray alloc] init];
    self.appStoreInitiatedProducts = [[NSMutableArray alloc] init];
    self.purchases = [[NSMutableSet alloc] init];

    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [self.channel setMethodCallHandler:nil];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"canMakePayments" isEqualToString:call.method]) {
        [self canMakePayments:result];
    } else if ([@"getItems" isEqualToString:call.method]) {
        NSArray<NSString*>* identifiers = (NSArray<NSString*>*)call.arguments[@"skus"];
        if (identifiers != nil) {
            [self fetchProducts:identifiers result:result];
        } else {
            result([FlutterError errorWithCode:@"ERROR" message:@"Invalid or missing arguments!" details:nil]);
        }
    } else if ([@"buyProductWithFinishTransaction" isEqualToString:call.method]) {
        NSString* identifier = (NSString*)call.arguments[@"sku"];
        NSLog(@"identifier %@", identifier);
        if (identifier != nil) {
            autoReceiptConform = true;
            [self purchase:identifier result:result];
        } else {
            result([FlutterError errorWithCode:@"ERROR" message:@"Invalid or missing arguments!" details:nil]);
        }
    } else if ([@"buyProductWithoutFinishTransaction" isEqualToString:call.method]) {
        NSString* identifier = (NSString*)call.arguments[@"sku"];
        NSLog(@"identifier %@", identifier);
        if (identifier != nil) {
            autoReceiptConform = false;
            [self purchase:identifier result:result];
        } else {
            result([FlutterError errorWithCode:@"ERROR" message:@"Invalid or missing arguments!" details:nil]);
        }
    } else if ([@"finishTransaction" isEqualToString:call.method]) {
        if (currentTransaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:currentTransaction];
        }
        currentTransaction = nil;
        result(@"Finished current transaction");
    } else if ([@"getAvailableItems" isEqualToString:call.method]) {
        [self getAvailableItems:result];
    } else if ([@"getAppStoreInitiatedProducts" isEqualToString:call.method]) {
        [self getAppStoreInitiatedProducts:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)canMakePayments:(FlutterResult)result {
    BOOL canMakePayments = [SKPaymentQueue canMakePayments];
    NSString* str = canMakePayments ? @"true" : @"false";
    result(str);
}

- (void)fetchProducts:(NSArray<NSString*>*)identifiers result:(FlutterResult)result {
    if (identifiers != nil && result != nil) {
        SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:identifiers]];
        [request setDelegate:self];
        [fetchProducts setObject:result forKey:[NSValue valueWithNonretainedObject:request]];

        [request start];
    } else if (result != nil){
        result([FlutterError
                errorWithCode:@"fetchProducts error"
                message:@"product identifier is nil"
                details:nil]);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSValue* key = [NSValue valueWithNonretainedObject:request];
    FlutterResult result = [fetchProducts objectForKey:key];
    if (result != nil) {
        [fetchProducts removeObjectForKey:key];
        result([FlutterError
                errorWithCode:[self standardErrorCode:(int)error.code]
                message:[self englishErrorCodeDescription:(int)error.code]
                details:nil]);
    }
}

- (void)productsRequest:(nonnull SKProductsRequest *)request didReceiveResponse:(nonnull SKProductsResponse *)response {
    NSValue* key = [NSValue valueWithNonretainedObject:request];
    FlutterResult result = [fetchProducts objectForKey:key];
    if (result == nil) return;
    [fetchProducts removeObjectForKey:key];
    products = [response products];

    NSMutableArray<NSDictionary*>* allValues = [[NSMutableArray alloc] init];
    [[response products] enumerateObjectsUsingBlock:^(SKProduct* product, NSUInteger idx, BOOL* stop) {
        [allValues addObject:[self getProductAsDictionary:product]];
    }];

    result(allValues);
}

-(NSDictionary *)getProductAsDictionary:(SKProduct*)product{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale;
    NSString* localizedPrice = [formatter stringFromNumber:product.price];
    NSString* introductoryPrice;
    NSString* introductoryPricePaymentMode = @"";
    NSString* introductoryPriceNumberOfPeriods = @"";
    NSString* introductoryPriceSubscriptionPeriod = @"";

    // NSString* itemType = @"Do not use this. It returned sub only before";

    NSString* currencyCode = @"";
    NSString* periodNumberIOS = @"0";
    NSString* periodUnitIOS = @"";


    if (@available(iOS 11.2, *)) {
        formatter.locale = product.introductoryPrice.priceLocale;
        introductoryPrice = [formatter stringFromNumber:product.introductoryPrice.price];

        // itemType = product.subscriptionPeriod ? @"sub" : @"iap";
        unsigned long numOfUnits = (unsigned long) product.subscriptionPeriod.numberOfUnits;
        SKProductPeriodUnit unit = product.subscriptionPeriod.unit;

        if (unit == SKProductPeriodUnitYear) {
            periodUnitIOS = @"YEAR";
        } else if (unit == SKProductPeriodUnitMonth) {
            periodUnitIOS = @"MONTH";
        } else if (unit == SKProductPeriodUnitWeek) {
            periodUnitIOS = @"WEEK";
        } else if (unit == SKProductPeriodUnitDay) {
            periodUnitIOS = @"DAY";
        }

        periodNumberIOS = [NSString stringWithFormat:@"%lu", numOfUnits];

        // subscriptionPeriod = product.subscriptionPeriod ? [product.subscriptionPeriod stringValue] : @"";
        // introductoryPrice = product.introductoryPrice != nil ? [NSString stringWithFormat:@"%@", product.introductoryPrice] : @"";
        if (product.introductoryPrice != nil) {
          //SKProductDiscount introductoryPriceObj = product.introductoryPrice;
          formatter.locale = product.introductoryPrice.priceLocale;
          introductoryPrice = [formatter stringFromNumber:product.introductoryPrice.price];

          switch (product.introductoryPrice.paymentMode) {
              case SKProductDiscountPaymentModeFreeTrial:
                  introductoryPricePaymentMode = @"FREETRIAL";
                  break;
              case SKProductDiscountPaymentModePayAsYouGo:
                  introductoryPricePaymentMode = @"PAYASYOUGO";
                  break;
              case SKProductDiscountPaymentModePayUpFront:
                  introductoryPricePaymentMode = @"PAYUPFRONT";
                  break;
              default:
                  introductoryPricePaymentMode = @"";
                  break;
          }

          introductoryPriceNumberOfPeriods = [@(product.introductoryPrice.numberOfPeriods) stringValue];

          if (product.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitDay) {
              introductoryPriceSubscriptionPeriod = @"DAY";
          }	else if (product.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitWeek) {
              introductoryPriceSubscriptionPeriod = @"WEEK";
          }	else if (product.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitMonth) {
              introductoryPriceSubscriptionPeriod = @"MONTH";
          } else if (product.introductoryPrice.subscriptionPeriod.unit == SKProductPeriodUnitYear) {
              introductoryPriceSubscriptionPeriod = @"YEAR";
          } else {
              introductoryPriceSubscriptionPeriod = @"";
          }

        } else {
          introductoryPrice = @"";
          introductoryPricePaymentMode = @"";
          introductoryPriceNumberOfPeriods = @"";
          introductoryPriceSubscriptionPeriod = @"";
        }
    }

    if (@available(iOS 10.0, *)) {
      currencyCode = product.priceLocale.currencyCode;
    }

    NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:
        product.productIdentifier, @"productId",
        [product.price stringValue], @"price",
        currencyCode, @"currency",
        product.localizedTitle ? product.localizedTitle : @"", @"title",
        product.localizedDescription ? product.localizedDescription : @"", @"description",
        localizedPrice, @"localizedPrice",
        periodNumberIOS, @"subscriptionPeriodNumberIOS",
        periodUnitIOS, @"subscriptionPeriodUnitIOS",
        introductoryPrice, @"introductoryPrice",
        introductoryPricePaymentMode, @"introductoryPricePaymentModeIOS",
        introductoryPriceNumberOfPeriods, @"introductoryPriceNumberOfPeriodsIOS",
        introductoryPriceSubscriptionPeriod, @"introductoryPriceSubscriptionPeriodIOS",
        nil
    ];
/*
    NSDictionary* obj = @{
      @"productId" : product.productIdentifier,
      @"price" : [product.price stringValue],
      @"currency" : currencyCode,
      // @"type": itemType,
      @"title" : product.localizedTitle ? product.localizedTitle : @"",
      @"description" : product.localizedDescription ? product.localizedDescription : @"",
      @"localizedPrice" : localizedPrice,
      @"subscriptionPeriodNumberIOS" : periodNumberIOS,
      @"subscriptionPeriodUnitIOS" : periodUnitIOS,
      @"introductoryPrice" : introductoryPrice,
      @"introductoryPricePaymentModeIOS" : introductoryPricePaymentMode,
      @"introductoryPriceNumberOfPeriodsIOS" : introductoryPriceNumberOfPeriods,
      @"introductoryPriceSubscriptionPeriodIOS" : introductoryPriceSubscriptionPeriod
    };
*/
    return obj;
}

- (void)purchase:(NSString*)identifier result:(FlutterResult)result {
    SKProduct* product;
    for (SKProduct* p in products) {
        if ([p.productIdentifier isEqualToString:identifier]) {
            product = p;
            break;
        }
    }

    if (product != nil) {
        SKPayment* payment = [SKPayment paymentWithProduct:product];
        [requestedPayments setObject:result forKey:payment];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        result([FlutterError errorWithCode:@"E_DEVELOPER_ERROR" message:@"Invalid product ID." details:nil]);
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        FlutterResult result = [requestedPayments objectForKey:transaction.payment];
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"\n\n Purchase Started !! \n\n");
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"\n\n\n\n\n Purchase Successful !! \n\n\n\n\n.");
                [self purchaseProcess:transaction];
                break;
            case SKPaymentTransactionStateRestored: // 기존 구매한 아이템 복구..
                NSLog(@"Restored ");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Deferred (awaiting approval via parental controls, etc.)");
                break;
            case SKPaymentTransactionStateFailed:
                if (result == nil) return;
                [requestedPayments removeObjectForKey:transaction.payment];

                result([FlutterError
                        errorWithCode:[self standardErrorCode:(int)transaction.error.code]
                        message:[self englishErrorCodeDescription:(int)transaction.error.code]
                        details:nil
                ]);
                NSLog(@"\n\n\n\n\n\n Purchase Failed  !! \n\n\n\n\n");
                break;
        }
    }
}

-(void)purchaseProcess:(SKPaymentTransaction *)transaction {
    if (autoReceiptConform) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        currentTransaction = nil;
    } else {
        currentTransaction = transaction;
    }

    NSDictionary* purchase = [self getPurchaseData:transaction];
    FlutterResult result = [requestedPayments objectForKey:transaction.payment];
    if (result != nil) {
        result(purchase);
        [requestedPayments removeObjectForKey:transaction.payment];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    // additionally send event
    [self.channel invokeMethod:@"iap-purchase-event" arguments: purchase];
}

- (NSDictionary *)getPurchaseData:(SKPaymentTransaction *)transaction {
    NSData *receiptData;
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    } else {
        receiptData = [transaction transactionReceipt];
    }

    if (receiptData == nil) return nil;

    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @(transaction.transactionDate.timeIntervalSince1970 * 1000), @"transactionDate",
        transaction.transactionIdentifier, @"transactionId",
        transaction.payment.productIdentifier, @"productId",
        [receiptData base64EncodedStringWithOptions:0], @"transactionReceipt",
        nil
    ];

/*
    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                     @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                                                                                     @"transactionId": transaction.transactionIdentifier,
                                                                                     @"productId": transaction.payment.productIdentifier,
                                                                                     @"transactionReceipt":[receiptData base64EncodedStringWithOptions:0]
                                                                                     }];
*/

    // originalTransaction is available for restore purchase and purchase of cancelled/expired subscriptions
    SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
    if (originalTransaction) {
        purchase[@"originalTransactionDateIOS"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
        purchase[@"originalTransactionIdentifierIOS"] = originalTransaction.transactionIdentifier;
    }

    return purchase;
}

- (void)purchased:(NSArray<SKPaymentTransaction*>*)transactions {
    NSMutableArray<FlutterResult>* results = [[NSMutableArray alloc] init];

    [transactions enumerateObjectsUsingBlock:^(SKPaymentTransaction* transaction, NSUInteger idx, BOOL* stop) {
        [self -> purchases addObject:transaction.payment.productIdentifier];
        FlutterResult result = [self -> requestedPayments objectForKey:transaction.payment];
        if (result != nil) {
            [self -> requestedPayments removeObjectForKey:transaction.payment];
            [results addObject:result];
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }];

    NSArray<NSString*>* productIdentifiers = [purchases allObjects];
    [results enumerateObjectsUsingBlock:^(FlutterResult result, NSUInteger idx, BOOL* stop) {
        result(productIdentifiers);
    }];
}

// getAvailablePurchases
- (void)getAvailableItems:(FlutterResult)result {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    flutterResult = result;
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {  ////////   RESTORE
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:queue.transactions.count];
    for(SKPaymentTransaction *transaction in queue.transactions) {
        if(transaction.transactionState == SKPaymentTransactionStateRestored) {
            NSDictionary *restored = [self getPurchaseData:transaction];
            [items addObject:restored];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
    if (flutterResult != nil) {
        flutterResult(items);
    }
    flutterResult = nil;
}

- (void)getAppStoreInitiatedProducts:(FlutterResult)result {
    NSMutableArray<NSDictionary*>* initiatedProducts = [[NSMutableArray alloc] init];
    for (SKProduct* p in appStoreInitiatedProducts) {
        [initiatedProducts addObject:[self getProductAsDictionary:p]];
    }
    result(initiatedProducts);
}

#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    // Save any purchases initiated through the App Store
    // Get the products by calling getAppStoreInitiatedProducts and handle the purchase in dart
    [appStoreInitiatedProducts addObject:product];
    return NO;
}
#endif

-(NSString *)standardErrorCode:(int)code {
    NSArray *descriptions = @[
                              @"E_UNKNOWN",
                              @"E_SERVICE_ERROR",
                              @"E_USER_CANCELLED",
                              @"E_USER_ERROR",
                              @"E_USER_ERROR",
                              @"E_ITEM_UNAVAILABLE",
                              @"E_REMOTE_ERROR",
                              @"E_NETWORK_ERROR",
                              @"E_SERVICE_ERROR"
                              ];
    
    if (code > descriptions.count - 1) {
        return descriptions[0];
    }
    return descriptions[code];
}

-(NSString *)englishErrorCodeDescription:(int)code {
    NSArray *descriptions = @[
                              @"An unknown or unexpected error has occured. Please try again later.",
                              @"Unable to process the transaction: your device is not allowed to make purchases.",
                              @"Cancelled.",
                              @"Oops! Payment information invalid. Did you enter your password correctly?",
                              @"Payment is not allowed on this device. If you are the one authorized to make purchases on this device, you can turn payments on in Settings.",
                              @"Sorry, but this product is currently not available in the store.",
                              @"Unable to make purchase: Cloud service permission denied.",
                              @"Unable to process transaction: Your internet connection isn't stable! Try again later.",
                              @"Unable to process transaction: Cloud service revoked."
                              ];
    
    if (0 <= code && code < descriptions.count)
        return descriptions[code];
    else
        return [NSString stringWithFormat:@"%@ (Error code: %d)", descriptions[0], code];
}

@end
