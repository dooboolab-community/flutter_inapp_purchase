package com.dooboolab.flutterinapppurchase;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.PurchaseHistoryResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import io.flutter.plugin.common.FlutterException;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** AndroidInappPurchasePlugin */
public class AndroidInappPurchasePlugin implements MethodCallHandler,  Application.ActivityLifecycleCallbacks {
  static private ArrayList<SkuDetails> skus;
  private final String TAG = "InappPurchasePlugin";
  private BillingClient billingClient;
  private Context context;
  private Activity activity;
  private MethodChannel channel;

  AndroidInappPurchasePlugin() {
    skus = new ArrayList<>();
  }

  public void setContext(Context context) {
    this.context = context;
  }

  public void setActivity(Activity activity) {
    this.activity = activity;
  }

  public void setChannel(MethodChannel channel) {
    this.channel = channel;
  }

  public void onDetachedFromActivity() {
    endBillingClientConnection();
  }

  @Override
  public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

  }

  @Override
  public void onActivityStarted(Activity activity) {

  }

  @Override
  public void onActivityResumed(Activity activity) {

  }

  @Override
  public void onActivityPaused(Activity activity) {

  }

  @Override
  public void onActivityDestroyed(Activity activity) {
    if (this.activity == activity && this.context != null) {
      ((Application) this.context).unregisterActivityLifecycleCallbacks(this);
      endBillingClientConnection();
    }
  }

  @Override
  public void onActivityStopped(Activity activity) {

  }

  @Override
  public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

  }

  @Override
  public void onMethodCall(final MethodCall call, final @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      try {
        result.success("Android " + android.os.Build.VERSION.RELEASE);
      } catch(IllegalStateException e){
        result.error(call.method, e.getMessage(), e.getLocalizedMessage());
      }
    }

    /*
     * initConnection
     */
    else if (call.method.equals("initConnection")) {
      if (billingClient != null) {
        result.success("Already started. Call endConnection method if you want to start over.");
        return;
      }

      billingClient = BillingClient.newBuilder(context).setListener(purchasesUpdatedListener)
              .enablePendingPurchases()
              .build();

      billingClient.startConnection(new BillingClientStateListener() {
        private boolean alreadyFinished = false;

        @Override
        public void onBillingSetupFinished(@NonNull BillingResult billingResult) {
          int responseCode = billingResult.getResponseCode();

          HashMap<String, Boolean> item = new HashMap<>();
          if (responseCode == BillingClient.BillingResponseCode.OK) {
            item.put("connected", true);
            channel.invokeMethod("connection-updated", item);
            if (alreadyFinished) return;
            alreadyFinished = true;
            result.success("Billing client ready");
          } else {
            item.put("connected", false);
            channel.invokeMethod("connection-updated", item);
            if (alreadyFinished) return;
            alreadyFinished = true;
            result.error(call.method, "responseCode: " + responseCode, "");
          }
        }

        @Override
        public void onBillingServiceDisconnected() {
            HashMap<String,Boolean> item = new HashMap<>();
            item.put("connected", false);
            channel.invokeMethod("connection-updated", item);
        }
      });
    }

    /*
     * endConnection
     */
    else if (call.method.equals("endConnection")) {
      if (billingClient != null) {
        try {
          billingClient.endConnection();
          billingClient = null;
          result.success("Billing client has ended.");
        } catch (Exception e) {
          result.error(call.method, e.getMessage(), "");
        }
      }
    }

    /*
     * consumeAllItems
     */
    else if (call.method.equals("consumeAllItems")) {
      try {
        final ArrayList<String> array = new ArrayList<>();
        Purchase.PurchasesResult purchasesResult = billingClient.queryPurchases(BillingClient.SkuType.INAPP);
        if (purchasesResult == null) {
          result.error(call.method,"refreshItem", "No results for query");
          return;
        }
        final List<Purchase> purchases = purchasesResult.getPurchasesList();
        if (purchases == null || purchases.size() == 0) {
          result.error(call.method, "refreshItem", "No purchases found");
          return;
        }

        for (Purchase purchase : purchases) {
          final ConsumeParams consumeParams = ConsumeParams.newBuilder()
              .setPurchaseToken(purchase.getPurchaseToken())
              .build();

          final ConsumeResponseListener listener = new ConsumeResponseListener() {
            @Override
            public void onConsumeResponse(@NonNull BillingResult billingResult, @NonNull String outToken) {
              array.add(outToken);
              if (purchases.size() == array.size()) {
                try {
                  result.success(array);
                } catch (FlutterException e) {
                  Log.e(TAG, e.getMessage());
                }
              }
            }
          };
          billingClient.consumeAsync(consumeParams, listener);
        }
      } catch (Error err) {
        result.error(call.method, err.getMessage(), "");
      }
    }

    /*
     * getItemsByType
     * arguments: type, skus
     */
    else if (call.method.equals("getItemsByType")) {
      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String type = call.argument("type");
      final ArrayList<String> skuList = call.argument("skus");

      SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
      params.setSkusList(skuList).setType(type);

      billingClient.querySkuDetailsAsync(params.build(), new SkuDetailsResponseListener() {
        @Override
        public void onSkuDetailsResponse(@NonNull BillingResult billingResult, List<SkuDetails> skuDetailsList) {
          int responseCode = billingResult.getResponseCode();
          if (responseCode != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
            return;
          }

          for (SkuDetails sku : skuDetailsList) {
            if (!skus.contains(sku)) {
              skus.add(sku);
            }
          }

          try {
            ArrayList<HashMap<String, Object>> items = new ArrayList<>();
            for (SkuDetails skuDetails : skuDetailsList) {
              items.add(buildSkuDetailsMap(skuDetails));
            }
            result.success(items);
          } catch (FlutterException fe) {
            result.error(call.method, fe.getMessage(), fe.getLocalizedMessage());
          }
        }
      });
    }

    /*
     * getAvailableItemsByType
     * arguments: type
     */
    else if (call.method.equals("getAvailableItemsByType")) {
      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String type = call.argument("type");

      final Purchase.PurchasesResult purchasesResult = billingClient.queryPurchases(type.equals("subs") ? BillingClient.SkuType.SUBS : BillingClient.SkuType.INAPP);
      final List<Purchase> purchases = purchasesResult.getPurchasesList();

      try {
        if (purchases != null) {
          ArrayList<HashMap<String, Object>> items = new ArrayList<>();

          for (Purchase purchase : purchases) {
            items.add(buildPurchaseMap(purchase));
          }

          result.success(items);
        }
      } catch (FlutterException fe) {
        result.error(call.method, fe.getMessage(), fe.getLocalizedMessage());
      }
    }

    /*
     * getPurchaseHistoryByType
     * arguments: type
     */
    else if (call.method.equals("getPurchaseHistoryByType")) {
      final String type = call.argument("type");

      billingClient.queryPurchaseHistoryAsync(type.equals("subs") ? BillingClient.SkuType.SUBS : BillingClient.SkuType.INAPP, new PurchaseHistoryResponseListener() {
        @Override
        public void onPurchaseHistoryResponse(@NonNull BillingResult billingResult, List<PurchaseHistoryRecord> purchaseHistoryRecordList) {
          if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
            return;
          }

          ArrayList<HashMap<String, Object>> items = new ArrayList<>();
          for (PurchaseHistoryRecord record : purchaseHistoryRecordList) {
            items.add(buildPurchaseHistoryRecordMap(record));
          }

          result.success(items);
        }
      });
    }

    /*
     * buyItemByType
     * arguments: type, obfuscatedAccountId, obfuscatedProfileId, sku, oldSku, prorationMode, purchaseToken
     */
    else if (call.method.equals("buyItemByType")) {
      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      // Not null
      final String sku = call.argument("sku");
      final String type = call.argument("type");
      final int prorationMode = call.argument("prorationMode");


      final String obfuscatedAccountId = call.argument("obfuscatedAccountId");
      final String obfuscatedProfileId = call.argument("obfuscatedProfileId");
      final String oldSku = call.argument("oldSku");
      final String purchaseToken = call.argument("purchaseToken");

      SkuDetails selectedSku = null;
      for (SkuDetails skuDetail : skus) {
        if (skuDetail.getSku().equals(sku)) {
          selectedSku = skuDetail;
          break;
        }
      }

      if (selectedSku == null) {
        String debugMessage = "The sku was not found. Please fetch products first by calling getItems";
        result.error(TAG, "buyItemByType", debugMessage);
        return;
      }

      BillingFlowParams.Builder builder = BillingFlowParams.newBuilder();

      // Subscription upgrade/downgrade
      if (type.equals(BillingClient.SkuType.SUBS) && oldSku != null && !oldSku.isEmpty() && purchaseToken!=null && !purchaseToken.isEmpty()) {
        builder.setOldSku(oldSku, purchaseToken);
      }
      if (prorationMode > 0) {
        builder.setReplaceSkusProrationMode(prorationMode);
      }
      if (obfuscatedAccountId != null) {
        builder.setObfuscatedAccountId(obfuscatedAccountId);
      }
      if (obfuscatedProfileId != null) {
        builder.setObfuscatedProfileId(obfuscatedProfileId);
      }

      builder.setSkuDetails(selectedSku);
      BillingFlowParams flowParams = builder.build();

      if (activity != null) {
        billingClient.launchBillingFlow(activity, flowParams);
      }
    }

    /*
     * acknowledgePurchase (For non-consumable purchases)
     * arguments: token
     */
    else if (call.method.equals("acknowledgePurchase")) {
      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String token = call.argument("token");
      AcknowledgePurchaseParams acknowledgePurchaseParams =
          AcknowledgePurchaseParams.newBuilder()
              .setPurchaseToken(token)
              .build();

      billingClient.acknowledgePurchase(acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener() {
        @Override
        public void onAcknowledgePurchaseResponse(@NonNull BillingResult billingResult) {
          if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
          } else {
            final HashMap<String,Object> resultMap = buildBillingResultMap(billingResult);
            result.success(resultMap);
          }
        }
      });
    }

    /*
     * consumeProduct (For consumable purchases)
     * arguments: token
     */
    else if (call.method.equals("consumeProduct")) {
      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String token = call.argument("token");
      final ConsumeParams params = ConsumeParams.newBuilder()
          .setPurchaseToken(token)
          .build();

      billingClient.consumeAsync(params, new ConsumeResponseListener() {
        @Override
        public void onConsumeResponse(@NonNull BillingResult billingResult,@NonNull String purchaseToken) {
          if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
          } else{
            final HashMap<String,Object> resultMap = buildBillingResultMap(billingResult);
            result.success(resultMap);
          }
        }
      });
    }
    else {
      result.notImplemented();
    }
  }

  private final PurchasesUpdatedListener purchasesUpdatedListener = new PurchasesUpdatedListener() {
    @Override
    public void onPurchasesUpdated(BillingResult billingResult, @Nullable List<Purchase> purchases) {

      if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
        final HashMap<String,Object> resultMap = buildBillingResultMap(billingResult);
        channel.invokeMethod("purchase-error", resultMap);
        return;
      }

      if (purchases == null){
        String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
        final HashMap<String,Object> resultMap = buildBillingResultMap(billingResult,errorData[0],"purchases returns null");
        channel.invokeMethod("purchase-error", resultMap);
        return;
      }

      for (Purchase purchase : purchases) {
        channel.invokeMethod("purchase-updated", buildPurchaseMap(purchase));
      }
    }
  };

  private void endBillingClientConnection() {
    if (billingClient != null) {
      try {
        billingClient.endConnection();
        billingClient = null;
      } catch (Exception ignored) {

      }
    }
  }

  private HashMap<String, Object> buildPurchaseMap(Purchase purchase){
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

    return map;
  }

  private HashMap<String, Object> buildPurchaseHistoryRecordMap(PurchaseHistoryRecord record){
    HashMap<String,Object> map = new HashMap<>();

    map.put("productId", record.getSku());
    map.put("signatureAndroid", record.getSignature());
    map.put("purchaseToken", record.getPurchaseToken());
    map.put("transactionDate", record.getPurchaseTime());
    map.put("transactionReceipt", record.getOriginalJson());

    return map;
  }

  private HashMap<String, Object> buildSkuDetailsMap(SkuDetails skuDetails){
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

  private HashMap<String, Object> buildBillingResultMap(BillingResult billingResult){
    String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
    return buildBillingResultMap(billingResult, errorData[0], errorData[1]);
  }

  private HashMap<String, Object> buildBillingResultMap(BillingResult billingResult, String errorCode, String message){
    HashMap<String,Object> map = new HashMap<>();

    map.put("responseCode", billingResult.getResponseCode());
    map.put("debugMessage", billingResult.getDebugMessage());
    map.put("message",  message);
    map.put("code", errorCode);

    return map;
  }
 }
