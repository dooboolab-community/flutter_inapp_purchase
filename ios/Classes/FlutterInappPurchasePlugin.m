#import "FlutterInappPurchasePlugin.h"

#import <IAPPromotionObserver.h>

@interface FlutterInappPurchasePlugin() {
    SKPaymentTransaction *currentTransaction;
    FlutterResult flutterResult;
    void (^receiptBlock)(NSData*, NSError*);
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
    [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
    self = [super init];
    self.fetchProducts = [[NSMutableDictionary alloc] init];
    self.requestedPayments = [[NSMutableDictionary alloc] init];
    self.products = [[NSArray alloc] init];
    self.appStoreInitiatedProducts = [[NSMutableArray alloc] init];
    self.purchases = [[NSMutableSet alloc] init];
    validProducts = [NSMutableArray array];
    [IAPPromotionObserver sharedObserver].delegate = self;

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
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [self canMakePayments:result];
    } else if ([@"endConnection" isEqualToString:call.method]) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
        result(@"Billing client ended");
    } else if ([@"getItems" isEqualToString:call.method]) {
        NSArray<NSString*>* identifiers = (NSArray<NSString*>*)call.arguments[@"skus"];
        if (identifiers != nil) {
            [self fetchProducts:identifiers result:result];
        } else {
            result([FlutterError errorWithCode:@"ERROR" message:@"Invalid or missing arguments!" details:nil]);
        }
    } else if ([@"buyProduct" isEqualToString:call.method]) {
        NSString* identifier = (NSString*)call.arguments[@"sku"];
        NSString* usernameHash = (NSString*)call.arguments[@"forUser"];
        SKProduct *product;

        for (SKProduct *p in validProducts) {
            if([identifier isEqualToString:p.productIdentifier]) {
                product = p;
                break;
            }
        }
        if (product) {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            payment.applicationUsername = usernameHash;
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        } else {
            NSDictionary *err = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Invalid product ID.", @"debugMessage",
                                 @"E_DEVELOPER_ERROR", @"code",
                                 @"Invalid product ID.", @"message",
                                 nil
                                 ];
            NSString* result = [self convertDicToJsonString:err];
            [self.channel invokeMethod:@"purchase-error" arguments:result];
        }
    } else if ([@"requestProductWithOfferIOS" isEqualToString:call.method]) {
        NSString* sku = (NSString*)call.arguments[@"sku"];
        NSDictionary* discountOffer = (NSDictionary*)call.arguments[@"withOffer"];
        NSString* usernameHash = (NSString*)call.arguments[@"forUser"];

        SKProduct *product;
        SKMutablePayment *payment;
        for (SKProduct *p in validProducts) {
            if([sku isEqualToString:p.productIdentifier]) {
                product = p;
                break;
            }
        }
        if (product) {
            payment = [SKMutablePayment paymentWithProduct:product];
#if __IPHONE_12_2
            if (@available(iOS 12.2, *)) {
                SKPaymentDiscount *discount = [[SKPaymentDiscount alloc]
                                               initWithIdentifier:discountOffer[@"identifier"]
                                               keyIdentifier:discountOffer[@"keyIdentifier"]
                                               nonce:[[NSUUID alloc] initWithUUIDString:discountOffer[@"nonce"]]
                                               signature:discountOffer[@"signature"]
                                               timestamp:discountOffer[@"timestamp"]
                                               ];
                payment.paymentDiscount = discount;
            }
#endif
            payment.applicationUsername = usernameHash;
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        } else {
            NSDictionary *err = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Invalid product ID.", @"debugMessage",
                                 @"Invalid product ID.", @"message",
                                 @"E_DEVELOPER_ERROR", @"code",
                                 nil
                                 ];
            NSString* result = [self convertDicToJsonString:err];
            [self.channel invokeMethod:@"purchase-error" arguments:result];
        }
    } else if ([@"requestProductWithQuantityIOS" isEqualToString:call.method]) {
        NSString* sku = (NSString*)call.arguments[@"sku"];
        NSString* quantity = (NSString*)call.arguments[@"quantity"];

        SKProduct *product;
        for (SKProduct *p in validProducts) {
            if([sku isEqualToString:p.productIdentifier]) {
                product = p;
                break;
            }
        }
        if (product) {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            payment.quantity = [quantity intValue];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        } else {
            NSDictionary *err = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Invalid product ID.", @"debugMessage",
                                 @"Invalid product ID.", @"message",
                                 @"E_DEVELOPER_ERROR", @"code",
                                 nil
                                 ];
            NSString* result = [self convertDicToJsonString:err];
            [self.channel invokeMethod:@"purchase-error" arguments:result];
        }
    } else if ([@"getPromotedProduct" isEqualToString:call.method]) {
        SKProduct *promotedProduct = [IAPPromotionObserver sharedObserver].product;
        result(promotedProduct ? promotedProduct.productIdentifier : [NSNull null]);
    } else if ([@"requestPromotedProduct" isEqualToString:call.method]) {
        SKPayment *promotedPayment = [IAPPromotionObserver sharedObserver].payment;
        if (promotedPayment) {
            NSLog(@"\n\n\n  ***  request promoted product. \n\n.");
            [[SKPaymentQueue defaultQueue] addPayment:promotedPayment];
            result(promotedPayment.productIdentifier);
        } else {
            result([FlutterError
                    errorWithCode:@"E_DEVELOPER_ERROR"
                    message:@"Invalid product ID."
                    details:nil]);
        }
    } else if ([@"requestReceipt" isEqualToString:call.method]) {
        [self requestReceiptDataWithBlock:^(NSData *receiptData, NSError *error) {
            if (error == nil) {
                result([receiptData base64EncodedStringWithOptions:0]);
            }
            else {
                result([FlutterError
                        errorWithCode:[self standardErrorCode:9]
                        message:@"Invalid receipt"
                        details:nil]);
            }
        }];
    } else if ([@"getPendingTransactions" isEqualToString:call.method]) {
        [self requestReceiptDataWithBlock:^(NSData *receiptData, NSError *error) {
            if (receiptData == nil) {
                result(nil);
            }
            else {
                NSArray<SKPaymentTransaction *> *transactions = [[SKPaymentQueue defaultQueue] transactions];
                NSMutableArray *output = [NSMutableArray array];
                
                for (SKPaymentTransaction *item in transactions) {
                    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     @(item.transactionDate.timeIntervalSince1970 * 1000), @"transactionDate",
                                                     item.transactionIdentifier, @"transactionId",
                                                     item.payment.productIdentifier, @"productId",
                                                     [receiptData base64EncodedStringWithOptions:0], @"transactionReceipt",
                                                     [NSNumber numberWithInt: item.transactionState], @"transactionStateIOS",
                                                     nil
                                                     ];
                    [output addObject:purchase];
                }
                
                result(output);
            }
        }];
    } else if ([@"finishTransaction" isEqualToString:call.method]) {
        NSString* transactionIdentifier = (NSString*)call.arguments[@"transactionIdentifier"];
        SKPaymentQueue *queue = [SKPaymentQueue defaultQueue];
        for(SKPaymentTransaction *transaction in queue.transactions) {
            if([transaction.transactionIdentifier isEqualToString:transactionIdentifier]) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }
        NSDictionary *err = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"finishTransaction", @"debugMessage",
                                transactionIdentifier, @"code",
                                @"finished", @"message",
                                nil
                                ];
        NSString* strResult = [self convertDicToJsonString:err];
        result(strResult);
    } else if ([@"clearTransaction" isEqualToString:call.method]) {
        NSArray *pendingTrans = [[SKPaymentQueue defaultQueue] transactions];
        NSLog(@"\n\n\n  ***  clear remaining Transactions. Call this before make a new transaction   \n\n.");
        for (int k = 0; k < pendingTrans.count; k++) {
            [[SKPaymentQueue defaultQueue] finishTransaction:pendingTrans[k]];
        }
        result(@"Cleared transactions");
    } else if ([@"getAvailableItems" isEqualToString:call.method]) {
        [self getAvailableItems:result];
    } else if ([@"getAppStoreInitiatedProducts" isEqualToString:call.method]) {
        [self getAppStoreInitiatedProducts:result];
    } else if ([@"showRedeemCodesIOS" isEqualToString:call.method]) {
#if __IPHONE_12_2
        if (@available(iOS 14.0, *)) {
            [[SKPaymentQueue defaultQueue] presentCodeRedemptionSheet];
            result(@"present PromoCodes");
            return;
            }
#endif
        result(@"the functionality is available starting from ios 14.0");

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

#pragma mark ===== StoreKit Delegate

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

    for (SKProduct* prod in response.products) {
        [self addProduct:prod];
    }
    NSMutableArray* items = [NSMutableArray array];
    
    for (SKProduct* product in validProducts) {
        [items addObject:[self getProductObject:product]];
    }

    result(items);
}

-(void)addProduct:(SKProduct *)aProd {
    NSLog(@"\n  Add new object : %@", aProd.productIdentifier);
    int delTar = -1;
    for (int k = 0; k < validProducts.count; k++) {
        SKProduct *cur = validProducts[k];
        if ([cur.productIdentifier isEqualToString:aProd.productIdentifier]) {
            delTar = k;
        }
    }
    if (delTar >= 0) {
        [validProducts removeObjectAtIndex:delTar];
    }
    [validProducts addObject:aProd];
}

-(NSDictionary *)getProductObject:(SKProduct*)product{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale;
    NSString* localizedPrice = [formatter stringFromNumber:product.price];
    NSString* introductoryPrice;
    NSString* introductoryPriceNumber = @"";
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
          introductoryPriceNumber = [product.introductoryPrice.price stringValue];

          switch (product.introductoryPrice.paymentMode) {
              case SKProductDiscountPaymentModeFreeTrial:
                  introductoryPricePaymentMode = @"FREETRIAL";
                  introductoryPriceNumberOfPeriods = [@(product.introductoryPrice.subscriptionPeriod.numberOfUnits) stringValue];
                  break;
              case SKProductDiscountPaymentModePayAsYouGo:
                  introductoryPricePaymentMode = @"PAYASYOUGO";
                  introductoryPriceNumberOfPeriods = [@(product.introductoryPrice.numberOfPeriods) stringValue];
                  break;
              case SKProductDiscountPaymentModePayUpFront:
                  introductoryPricePaymentMode = @"PAYUPFRONT";
                  introductoryPriceNumberOfPeriods = [@(product.introductoryPrice.subscriptionPeriod.numberOfUnits) stringValue];
                  break;
              default:
                  introductoryPricePaymentMode = @"";
                  introductoryPriceNumberOfPeriods = @"0";
                  break;
          }

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
          introductoryPriceNumber = @"";
          introductoryPricePaymentMode = @"";
          introductoryPriceNumberOfPeriods = @"";
          introductoryPriceSubscriptionPeriod = @"";
        }
    }

    if (@available(iOS 10.0, *)) {
      currencyCode = product.priceLocale.currencyCode;
    }
    
    NSArray *discounts;
#if __IPHONE_12_2
    if (@available(iOS 12.2, *)) {
        discounts = [self getDiscountData:[product.discounts copy]];
    }
#endif

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
        introductoryPriceNumber, @"introductoryPriceNumberIOS",
        introductoryPricePaymentMode, @"introductoryPricePaymentModeIOS",
        introductoryPriceNumberOfPeriods, @"introductoryPriceNumberOfPeriodsIOS",
        introductoryPriceSubscriptionPeriod, @"introductoryPriceSubscriptionPeriodIOS",
        discounts, @"discounts",
        nil
    ];
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

- (NSMutableArray *)getDiscountData:(NSArray *)discounts {
    NSMutableArray *mappedDiscounts = [NSMutableArray arrayWithCapacity:[discounts count]];
    NSString *localizedPrice;
    NSString *paymendMode;
    NSString *subscriptionPeriods;
    NSString *discountType;
    
    if (@available(iOS 11.2, *)) {
        for(SKProductDiscount *discount in discounts) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterCurrencyStyle;
            formatter.locale = discount.priceLocale;
            localizedPrice = [formatter stringFromNumber:discount.price];
            NSString *numberOfPeriods;
            
            switch (discount.paymentMode) {
                case SKProductDiscountPaymentModeFreeTrial:
                    paymendMode = @"FREETRIAL";
                    numberOfPeriods = [@(discount.subscriptionPeriod.numberOfUnits) stringValue];
                    break;
                case SKProductDiscountPaymentModePayAsYouGo:
                    paymendMode = @"PAYASYOUGO";
                    numberOfPeriods = [@(discount.numberOfPeriods) stringValue];
                    break;
                case SKProductDiscountPaymentModePayUpFront:
                    paymendMode = @"PAYUPFRONT";
                    numberOfPeriods = [@(discount.subscriptionPeriod.numberOfUnits) stringValue];
                    break;
                default:
                    paymendMode = @"";
                    numberOfPeriods = @"0";
                    break;
            }
            
            switch (discount.subscriptionPeriod.unit) {
                case SKProductPeriodUnitDay:
                    subscriptionPeriods = @"DAY";
                    break;
                case SKProductPeriodUnitWeek:
                    subscriptionPeriods = @"WEEK";
                    break;
                case SKProductPeriodUnitMonth:
                    subscriptionPeriods = @"MONTH";
                    break;
                case SKProductPeriodUnitYear:
                    subscriptionPeriods = @"YEAR";
                    break;
                default:
                    subscriptionPeriods = @"";
            }

            NSString* discountIdentifier = @"";
#if __IPHONE_12_2
            if (@available(iOS 12.2, *)) {
                discountIdentifier = discount.identifier;
                switch (discount.type) {
                    case SKProductDiscountTypeIntroductory:
                        discountType = @"INTRODUCTORY";
                        break;
                    case SKProductDiscountTypeSubscription:
                        discountType = @"SUBSCRIPTION";
                        break;
                    default:
                        discountType = @"";
                        break;
                }
                
            }
#endif
            
            [mappedDiscounts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        discountIdentifier, @"identifier",
                                        discountType, @"type",
                                        numberOfPeriods, @"numberOfPeriods",
                                        discount.price, @"price",
                                        localizedPrice, @"localizedPrice",
                                        paymendMode, @"paymentMode",
                                        subscriptionPeriods, @"subscriptionPeriod",
                                        nil
                                        ]];
        }
    }
    
    return mappedDiscounts;
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"\n\n Purchase Started !! \n\n");
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"\n\n\n\n\n Purchase Successful !! \n\n\n\n\n.");
                [self purchaseProcess:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Restored ");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Deferred (awaiting approval via parental controls, etc.)");
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [requestedPayments removeObjectForKey:transaction.payment];
                NSDictionary *err = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"SKPaymentTransactionStateFailed", @"debugMessage",
                                     [self standardErrorCode:(int)transaction.error.code], @"code",
                                     [self englishErrorCodeDescription:(int)transaction.error.code], @"message",
                                     nil
                                     ];
                NSString* result = [self convertDicToJsonString:err];

                [self.channel invokeMethod:@"purchase-error" arguments: [NSString stringWithFormat:@"%@", result]];
                NSLog(@"\n\n\n\n\n\n Purchase Failed  !! \n\n\n\n\n");
                break;
        }
    }
}

-(NSString *)convertDicToJsonString:(NSDictionary *)dic {
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString* jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonDataStr;
}

-(void)purchaseProcess:(SKPaymentTransaction *)transaction {
    [self getPurchaseData:transaction withBlock:^(NSDictionary *purchase) {
        NSString* result = [self convertDicToJsonString:purchase];
        [self.channel invokeMethod:@"purchase-updated" arguments: result];
    }];
}

- (void) getPurchaseData:(SKPaymentTransaction *)transaction withBlock:(void (^)(NSDictionary *transactionDict))block {
    [self requestReceiptDataWithBlock:^(NSData *receiptData, NSError *error) {
        if (receiptData == nil) {
            block(nil);
        }
        else {
            NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @(transaction.transactionDate.timeIntervalSince1970 * 1000), @"transactionDate",
                                             transaction.transactionIdentifier, @"transactionId",
                                             transaction.payment.productIdentifier, @"productId",
                                             [receiptData base64EncodedStringWithOptions:0], @"transactionReceipt",
                                             [NSNumber numberWithInt: transaction.transactionState], @"transactionStateIOS",
                                             nil
                                             ];
            
            // originalTransaction is available for restore purchase and purchase of cancelled/expired subscriptions
            SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
            if (originalTransaction) {
                purchase[@"originalTransactionDateIOS"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
                purchase[@"originalTransactionIdentifierIOS"] = originalTransaction.transactionIdentifier;
            }
            
            block(purchase);
        }
    }];
}

// getAvailablePurchases
- (void)getAvailableItems:(FlutterResult)result {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    flutterResult = result;
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {  ////////   RESTORE
    NSLog(@"\n\n\n  paymentQueueRestoreCompletedTransactionsFinished  \n\n.");
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:queue.transactions.count];
    
    for(SKPaymentTransaction *transaction in queue.transactions) {
        if(transaction.transactionState == SKPaymentTransactionStateRestored
           || transaction.transactionState == SKPaymentTransactionStatePurchased) {
            [self getPurchaseData:transaction withBlock:^(NSDictionary *restored) {
                [items addObject:restored];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }];
        }
    }
    
    if (flutterResult != nil) {
        flutterResult(items);
    }
    flutterResult = nil;
}

-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    if (flutterResult != nil) {
        flutterResult([FlutterError
                       errorWithCode:[self standardErrorCode:(int)error.code]
                       message:[self englishErrorCodeDescription:(int)error.code]
                       details:nil]);
    }
    flutterResult = nil;
}

- (void)getAppStoreInitiatedProducts:(FlutterResult)result {
    NSMutableArray<NSDictionary*>* initiatedProducts = [[NSMutableArray alloc] init];
    for (SKProduct* p in appStoreInitiatedProducts) {
        [initiatedProducts addObject:[self getProductObject:p]];
    }
    result(initiatedProducts);
}

#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    // Save any purchases initiated through the App Store
    // Get the products by calling getAppStoreInitiatedProducts and handle the purchase in dart
    [appStoreInitiatedProducts addObject:product];
    [self.channel invokeMethod:@"iap-promoted-product" arguments:product.productIdentifier];
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

#pragma mark - Receipt

- (void) requestReceiptDataWithBlock:(void (^)(NSData *data, NSError *error))block {
    if ([self isReceiptPresent] == NO) {
        SKReceiptRefreshRequest *refreshRequest = [[SKReceiptRefreshRequest alloc]init];
        refreshRequest.delegate = self;
        [refreshRequest start];
        receiptBlock = block;
    }
    else {
        receiptBlock = nil;
        block([self receiptData], nil);
    }
}

- (BOOL) isReceiptPresent {
    NSURL *receiptURL = [[NSBundle mainBundle]appStoreReceiptURL];
    NSError *canReachError = nil;
    [receiptURL checkResourceIsReachableAndReturnError:&canReachError];
    return canReachError == nil;
}

- (NSData *) receiptData {
    NSURL *receiptURL = [[NSBundle mainBundle]appStoreReceiptURL];
    NSData *receiptData = [[NSData alloc]initWithContentsOfURL:receiptURL];
    return receiptData;
}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request {
    if([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        if ([self isReceiptPresent] == YES) {
            NSLog(@"Receipt refreshed success.");
            if(receiptBlock) {
                receiptBlock([self receiptData], nil);
            }
        }
        else if(receiptBlock) {
            NSLog(@"Finished but receipt refreshed failed!");
            NSError *error = [[NSError alloc]initWithDomain:@"Receipt request finished but it failed!" code:10 userInfo:nil];
            receiptBlock(nil, error);
        }
        receiptBlock = nil;
    }
}

@end
