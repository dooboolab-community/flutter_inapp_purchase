#import "FlutterInappPurchasePlugin.h"

@interface FlutterInappPurchasePlugin() {
    BOOL autoReceiptConform;
    SKPaymentTransaction *currentTransaction;
    FlutterResult flutterResult;
}

@property (atomic, retain) NSMutableDictionary<NSValue*, FlutterResult>* fetchProducts;
@property (atomic, retain) NSMutableDictionary<SKPayment*, FlutterResult>* requestedPayments;
@property (atomic, retain) NSArray<SKProduct*>* products;
@property (atomic, retain) NSMutableSet<NSString*>* purchases;
@property (nonatomic, retain) FlutterMethodChannel* channel;

@end

@implementation FlutterInappPurchasePlugin

@synthesize fetchProducts;
@synthesize requestedPayments;
@synthesize products;
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
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:identifiers]];
    [request setDelegate:self];
    [fetchProducts setObject:result forKey:[NSValue valueWithNonretainedObject:request]];

    [request start];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSValue* key = [NSValue valueWithNonretainedObject:request];
    FlutterResult result = [fetchProducts objectForKey:key];
    if (result != nil) {
        [fetchProducts removeObjectForKey:key];
        result([FlutterError errorWithCode:@"ERROR" message:@"Failed to make IAP request!" details:nil]);
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
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = product.priceLocale;
        NSString *localizedPrice = [formatter stringFromNumber:product.price];

        NSString* itemType = @"Do not use this. It returned sub only before";
        NSString* currencyCode = @"";

        if (@available(iOS 10.0, *)) {
          currencyCode = product.priceLocale.currencyCode;
        }

        NSString* obj = @{
          @"productId" : product.productIdentifier,
          @"price" : [product.price stringValue],
          @"currency" : currencyCode,
          @"type": itemType,
          @"title" : product.localizedTitle ? product.localizedTitle : @"",
          @"description" : product.localizedDescription ? product.localizedDescription : @"",
          @"localizedPrice" : localizedPrice
        };


        [allValues addObject:obj];
    }];

    result(allValues);
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
        result([FlutterError errorWithCode:@"ERROR" message:@"Failed to make a payment!" details:nil]);
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
                result(@"purchase failed");
                NSLog(@"\n\n\n\n\n\n Purchase Failed  !! \n\n\n\n\n");
                break;
        }
    }
}

-(void)purchaseProcess:(SKPaymentTransaction *)transaction {
    NSMutableArray<FlutterResult>* results = [[NSMutableArray alloc] init];
    if (autoReceiptConform) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        currentTransaction = nil;
    } else {
        currentTransaction = transaction;
    }

    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSDictionary* purchase = [self getPurchaseData:transaction];
    FlutterResult result = [requestedPayments objectForKey:transaction.payment];
    if (result != nil) {
        result(purchase);
        [requestedPayments removeObjectForKey:transaction.payment];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (NSDictionary *)getPurchaseData:(SKPaymentTransaction *)transaction {
    NSData *receiptData;
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    } else {
        receiptData = [transaction transactionReceipt];
    }

    if (receiptData == nil) return nil;

    NSMutableDictionary *purchase = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                     @"transactionDate": @(transaction.transactionDate.timeIntervalSince1970 * 1000),
                                                                                     @"transactionId": transaction.transactionIdentifier,
                                                                                     @"productId": transaction.payment.productIdentifier,
                                                                                     @"transactionReceipt":[receiptData base64EncodedStringWithOptions:0]
                                                                                     }];
    // originalTransaction is available for restore purchase and purchase of cancelled/expired subscriptions
    SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
    if (originalTransaction) {
        purchase[@"originalTransactionDate"] = @(originalTransaction.transactionDate.timeIntervalSince1970 * 1000);
        purchase[@"originalTransactionIdentifier"] = originalTransaction.transactionIdentifier;
    }

    return purchase;
}

- (void)purchased:(NSArray<SKPaymentTransaction*>*)transactions {
    NSMutableArray<FlutterResult>* results = [[NSMutableArray alloc] init];

    [transactions enumerateObjectsUsingBlock:^(SKPaymentTransaction* transaction, NSUInteger idx, BOOL* stop) {
        [purchases addObject:transaction.payment.productIdentifier];
        FlutterResult result = [requestedPayments objectForKey:transaction.payment];
        if (result != nil) {
            [requestedPayments removeObjectForKey:transaction.payment];
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

@end
