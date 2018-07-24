#import "FlutterInappPlugin.h"
@interface FlutterInappPlugin()

@property (atomic, retain) NSMutableArray<FlutterResult>* fetchPurchases;
@property (atomic, retain) NSMutableDictionary<NSValue*, FlutterResult>* fetchProducts;
@property (atomic, retain) NSMutableDictionary<SKPayment*, FlutterResult>* requestedPayments;
@property (atomic, retain) NSArray<SKProduct*>* products;
@property (atomic, retain) NSMutableSet<NSString*>* purchases;
@property (nonatomic, retain) FlutterMethodChannel* channel;

@end

@implementation FlutterInappPlugin

@synthesize fetchPurchases;
@synthesize fetchProducts;
@synthesize requestedPayments;
@synthesize products;
@synthesize purchases;
@synthesize channel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterInappPlugin* instance = [[FlutterInappPlugin alloc] init];
    instance.channel = [FlutterMethodChannel
                        methodChannelWithName:@"flutter_inapp"
                        binaryMessenger:[registrar messenger]];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
    self = [super init];

    self.fetchPurchases = [[NSMutableArray alloc] init];
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
    } else if ([@"buyProduct" isEqualToString:call.method]) {
        NSString* identifier = (NSString*)call.arguments[@"sku"];
        if (identifier != nil) {
            [self purchase:identifier result:result];
        } else {
            result([FlutterError errorWithCode:@"ERROR" message:@"Invalid or missing arguments!" details:nil]);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)canMakePayments:(FlutterResult)result {
    BOOL canMakePayments = [SKPaymentQueue canMakePayments];
    NSString* str = canMakePayments ? @"true" : @"false";
    result(str);
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

@end
