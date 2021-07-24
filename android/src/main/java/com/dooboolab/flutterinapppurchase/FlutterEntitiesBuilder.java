package com.dooboolab.flutterinapppurchase;

import com.amazon.device.iap.model.Product;
import com.amazon.device.iap.model.ProductType;
import com.amazon.device.iap.model.Receipt;
import com.android.billingclient.api.AccountIdentifiers;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.SkuDetails;

import java.util.HashMap;

class FlutterEntitiesBuilder {
    static public HashMap<String, Object> buildPurchaseMap(Purchase purchase){
        HashMap<String,Object> map = new HashMap<>();

        // part of PurchaseHistory object
        map.put("productId", purchase.getSku());
        map.put("signatureAndroid", purchase.getSignature());
        map.put("purchaseToken", purchase.getPurchaseToken());
        map.put("transactionDate", purchase.getPurchaseTime());
        map.put("transactionReceipt", purchase.getOriginalJson());

        // additional fields for purchase
        map.put("orderId", purchase.getOrderId());
        map.put("transactionId", purchase.getOrderId());
        map.put("autoRenewingAndroid", purchase.isAutoRenewing());
        map.put("isAcknowledgedAndroid", purchase.isAcknowledged());
        map.put("purchaseStateAndroid", purchase.getPurchaseState());

        final AccountIdentifiers identifiers = purchase.getAccountIdentifiers();
        if(identifiers!=null){
            map.put("obfuscatedAccountId", identifiers.getObfuscatedAccountId());
            map.put("obfuscatedProfileId", identifiers.getObfuscatedProfileId());
        }


        return map;
    }

    // Amazon
    static public HashMap<String, Object> buildPurchaseMap(Receipt receipt){
        HashMap<String,Object> map = new HashMap<>();

        // part of PurchaseHistory object
        map.put("productId", receipt.getSku());
        map.put("transactionDate", receipt.getPurchaseDate().getTime());
        map.put("transactionReceipt", receipt.getReceiptId());
        map.put("transactionId", receipt.getReceiptId());


        return map;
    }

    static public HashMap<String, Object> buildPurchaseHistoryRecordMap(PurchaseHistoryRecord record){
        HashMap<String,Object> map = new HashMap<>();

        map.put("productId", record.getSku());
        map.put("signatureAndroid", record.getSignature());
        map.put("purchaseToken", record.getPurchaseToken());
        map.put("transactionDate", record.getPurchaseTime());
        map.put("transactionReceipt", record.getOriginalJson());

        return map;
    }

    static public HashMap<String, Object> buildSkuDetailsMap(SkuDetails skuDetails){
        HashMap<String,Object> map = new HashMap<>();

        map.put("productId", skuDetails.getSku());
        map.put("price", String.valueOf(skuDetails.getPriceAmountMicros() / 1000000f));
        map.put("currency", skuDetails.getPriceCurrencyCode());
        map.put("type", skuDetails.getType());
        map.put("localizedPrice", skuDetails.getPrice());
        map.put("title", skuDetails.getTitle());
        map.put("description", skuDetails.getDescription());
        map.put("introductoryPrice", skuDetails.getIntroductoryPrice());
        map.put("subscriptionPeriodAndroid", skuDetails.getSubscriptionPeriod());
        map.put("freeTrialPeriodAndroid", skuDetails.getFreeTrialPeriod());
        map.put("introductoryPriceCyclesAndroid", skuDetails.getIntroductoryPriceCycles());
        map.put("introductoryPricePeriodAndroid", skuDetails.getIntroductoryPricePeriod());
        map.put("iconUrl", skuDetails.getIconUrl());
        map.put("originalJson", skuDetails.getOriginalJson());
        map.put("originalPrice", skuDetails.getOriginalPriceAmountMicros() / 1000000f);

        return map;
    }

    // Amazon
    static public HashMap<String, Object> buildSkuDetailsMap(Product amazonProduct){
        HashMap<String,Object> map = new HashMap<>();

        map.put("productId", amazonProduct.getSku());
        map.put("localizedPrice", amazonProduct.getPrice());
        map.put("title", amazonProduct.getTitle());
        map.put("description", amazonProduct.getDescription());

        ProductType productType = amazonProduct.getProductType();
        switch (productType) {
            case ENTITLED:
            case CONSUMABLE:
                map.put("type", "inapp");
                break;
            case SUBSCRIPTION:
                map.put("type", "subs");
                break;
        }

        return map;
    }

    static public HashMap<String, Object> buildBillingResultMap(BillingResult billingResult){
        String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
        return buildBillingResultMap(billingResult, errorData[0], errorData[1]);
    }

    static public HashMap<String, Object> buildBillingResultMap(BillingResult billingResult, String errorCode, String message){
        HashMap<String,Object> map = new HashMap<>();

        map.put("responseCode", billingResult.getResponseCode());
        map.put("debugMessage", billingResult.getDebugMessage());
        map.put("message",  message);
        map.put("code", errorCode);

        return map;
    }
}
