package com.dooboolab.flutterinapppurchase;

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

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
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
  public void onMethodCall(final MethodCall call, final Result result) {
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
        public void onBillingSetupFinished(BillingResult billingResult) {
          try {
            int responseCode = billingResult.getResponseCode();

            if (responseCode == BillingClient.BillingResponseCode.OK) {
              JSONObject item = new JSONObject();
              item.put("connected", true);
              channel.invokeMethod("connection-updated", item.toString());
              if (alreadyFinished) return;
              alreadyFinished = true;
              result.success("Billing client ready");
            } else {
              JSONObject item = new JSONObject();
              item.put("connected", false);
              channel.invokeMethod("connection-updated", item.toString());
              if (alreadyFinished) return;
              alreadyFinished = true;
              result.error(call.method, "responseCode: " + responseCode, "");
            }
          } catch (JSONException je) {
            je.printStackTrace();
          }

        }

        @Override
        public void onBillingServiceDisconnected() {
          try {
            JSONObject item = new JSONObject();
            item.put("connected", false);
            channel.invokeMethod("connection-updated", item.toString());
          } catch (JSONException je) {
            je.printStackTrace();
          }
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
            public void onConsumeResponse(BillingResult billingResult, String outToken) {
              array.add(outToken);
              if (purchases.size() == array.size()) {
                try {
                  result.success(array.toString());
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

      String type = call.argument("type");
      final ArrayList<String> skuArr = call.argument("skus");


      ArrayList<String> skuList = new ArrayList<>();

      for (int i = 0; i < skuArr.size(); i++) {
        skuList.add(skuArr.get(i));
      }

      SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
      params.setSkusList(skuList).setType(type);

      billingClient.querySkuDetailsAsync(params.build(), new SkuDetailsResponseListener() {
        @Override
        public void onSkuDetailsResponse(BillingResult billingResult, List<SkuDetails> skuDetailsList) {
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
            JSONArray items = new JSONArray();
            for (SkuDetails skuDetails : skuDetailsList) {
              JSONObject item = new JSONObject();
              item.put("productId", skuDetails.getSku());
              item.put("price", String.valueOf(skuDetails.getPriceAmountMicros() / 1000000f));
              item.put("currency", skuDetails.getPriceCurrencyCode());
              item.put("type", skuDetails.getType());
              item.put("localizedPrice", skuDetails.getPrice());
              item.put("title", skuDetails.getTitle());
              item.put("description", skuDetails.getDescription());
              item.put("introductoryPrice", skuDetails.getIntroductoryPrice());
              item.put("subscriptionPeriodAndroid", skuDetails.getSubscriptionPeriod());
              item.put("freeTrialPeriodAndroid", skuDetails.getFreeTrialPeriod());
              item.put("introductoryPriceCyclesAndroid", skuDetails.getIntroductoryPriceCycles());
              item.put("introductoryPricePeriodAndroid", skuDetails.getIntroductoryPricePeriod());
              // new
              item.put("iconUrl", skuDetails.getIconUrl());
              item.put("originalJson", skuDetails.getOriginalJson());
              item.put("originalPrice", skuDetails.getOriginalPriceAmountMicros() / 1000000f);
              items.put(item);
            }
            result.success(items.toString());
          } catch (JSONException je) {
            je.printStackTrace();
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
      final JSONArray items = new JSONArray();
      Purchase.PurchasesResult purchasesResult = billingClient.queryPurchases(type.equals("subs") ? BillingClient.SkuType.SUBS : BillingClient.SkuType.INAPP);
      final List<Purchase> purchases = purchasesResult.getPurchasesList();

      try {
        if (purchases != null) {
          for (Purchase purchase : purchases) {
            JSONObject item = new JSONObject();
            item.put("productId", purchase.getSku());
            item.put("transactionId", purchase.getOrderId());
            item.put("transactionDate", purchase.getPurchaseTime());
            item.put("transactionReceipt", purchase.getOriginalJson());
            item.put("orderId", purchase.getOrderId());
            item.put("purchaseToken", purchase.getPurchaseToken());
            item.put("signatureAndroid", purchase.getSignature());
            item.put("purchaseStateAndroid", purchase.getPurchaseState());

            if (type.equals(BillingClient.SkuType.INAPP)) {
              item.put("isAcknowledgedAndroid", purchase.isAcknowledged());
            } else if (type.equals(BillingClient.SkuType.SUBS)) {
              item.put("autoRenewingAndroid", purchase.isAutoRenewing());
            }
            items.put(item);
          }
          result.success(items.toString());
        }
      } catch (JSONException je) {
        result.error(call.method, je.getMessage(), je.getLocalizedMessage());
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
        public void onPurchaseHistoryResponse(BillingResult billingResult, List<PurchaseHistoryRecord> purchaseHistoryRecordList) {
          if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
            return;
          }

          JSONArray items = new JSONArray();

          try {
            for (PurchaseHistoryRecord purchase : purchaseHistoryRecordList) {
              JSONObject item = new JSONObject();
              item.put("productId", purchase.getSku());
              item.put("transactionDate", purchase.getPurchaseTime());
              item.put("transactionReceipt", purchase.getOriginalJson());
              item.put("purchaseToken", purchase.getPurchaseToken());
              item.put("dataAndroid", purchase.getOriginalJson());
              item.put("signatureAndroid", purchase.getSignature());
              items.put(item);
            }
            result.success(items.toString());
          } catch (JSONException je) {
            je.printStackTrace();
          }
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

      final String type = call.argument("type");
      final String obfuscatedAccountId = call.argument("obfuscatedAccountId");
      final String obfuscatedProfileId = call.argument("obfuscatedProfileId");
      final String sku = call.argument("sku");
      final String oldSku = call.argument("oldSku");
      final int prorationMode = call.argument("prorationMode");
      final String purchaseToken = call.argument("purchaseToken");

      BillingFlowParams.Builder builder = BillingFlowParams.newBuilder();

      if (type.equals(BillingClient.SkuType.SUBS) && oldSku != null && !oldSku.isEmpty()) {
        // Subscription upgrade/downgrade
        builder.setOldSku(oldSku, purchaseToken);
      }

      if (type.equals(BillingClient.SkuType.SUBS) && oldSku != null && !oldSku.isEmpty()) {
        // Subscription upgrade/downgrade
        if (prorationMode != -1) {
          builder.setOldSku(oldSku, purchaseToken);
          if (prorationMode == BillingFlowParams.ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE) {
            builder.setReplaceSkusProrationMode(BillingFlowParams.ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE);
          } else if (prorationMode == BillingFlowParams.ProrationMode.IMMEDIATE_WITHOUT_PRORATION) {
            builder.setReplaceSkusProrationMode(BillingFlowParams.ProrationMode.IMMEDIATE_WITHOUT_PRORATION);
          } else {
            builder.setOldSku(oldSku, purchaseToken);
          }
        } else {
          builder.setOldSku(oldSku, purchaseToken);
        }
      }

      if (prorationMode != 0 && prorationMode != -1) {
        builder.setReplaceSkusProrationMode(prorationMode);
      }

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
      final String token = call.argument("token");

      if (billingClient == null || !billingClient.isReady()) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      AcknowledgePurchaseParams acknowledgePurchaseParams =
          AcknowledgePurchaseParams.newBuilder()
              .setPurchaseToken(token)
              .build();
      billingClient.acknowledgePurchase(acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener() {
        @Override
        public void onAcknowledgePurchaseResponse(BillingResult billingResult) {
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          result.error(call.method, errorData[0], errorData[1]);
          return;
        }
          try {
            JSONObject item = new JSONObject();
            item.put("responseCode", billingResult.getResponseCode());
            item.put("debugMessage", billingResult.getDebugMessage());
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            item.put("code", errorData[0]);
            item.put("message", errorData[1]);
            result.success(item.toString());
          } catch (JSONException je) {
            je.printStackTrace();
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
        public void onConsumeResponse(BillingResult billingResult, String purchaseToken) {
          if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            result.error(call.method, errorData[0], errorData[1]);
            return;
          }

          try {
            JSONObject item = new JSONObject();
            item.put("responseCode", billingResult.getResponseCode());
            item.put("debugMessage", billingResult.getDebugMessage());
            String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
            item.put("code", errorData[0]);
            item.put("message", errorData[1]);
            result.success(item.toString());
          } catch (JSONException je) {
            result.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", je.getMessage());
          }
        }
      });
    }

    /*
     * else
     */
    else {
      result.notImplemented();
    }
  }

  private PurchasesUpdatedListener purchasesUpdatedListener = new PurchasesUpdatedListener() {
    @Override
    public void onPurchasesUpdated(BillingResult billingResult, @Nullable List<Purchase> purchases) {

      try {
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
          JSONObject json = new JSONObject();
          json.put("responseCode", billingResult.getResponseCode());
          json.put("debugMessage", billingResult.getDebugMessage());
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          json.put("code", errorData[0]);
          json.put("message", errorData[1]);
          channel.invokeMethod("purchase-error", json.toString());
          return;
        }

        if (purchases != null) {
          for (Purchase purchase : purchases) {
            JSONObject item = new JSONObject();
            item.put("productId", purchase.getSku());
            item.put("transactionId", purchase.getOrderId());
            item.put("transactionDate", purchase.getPurchaseTime());
            item.put("transactionReceipt", purchase.getOriginalJson());
            item.put("purchaseToken", purchase.getPurchaseToken());
            item.put("orderId", purchase.getOrderId());

            item.put("dataAndroid", purchase.getOriginalJson());
            item.put("signatureAndroid", purchase.getSignature());
            item.put("autoRenewingAndroid", purchase.isAutoRenewing());
            item.put("isAcknowledgedAndroid", purchase.isAcknowledged());
            item.put("purchaseStateAndroid", purchase.getPurchaseState());
            item.put("originalJsonAndroid", purchase.getOriginalJson());


            channel.invokeMethod("purchase-updated", item.toString());
          }
        } else {
          JSONObject json = new JSONObject();
          json.put("responseCode", billingResult.getResponseCode());
          json.put("debugMessage", billingResult.getDebugMessage());
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          json.put("code", errorData[0]);
          json.put("message", "purchases returns null.");
          channel.invokeMethod("purchase-error", json.toString());
        }
      } catch (JSONException je) {
        channel.invokeMethod("purchase-error", je.getMessage());
      }
    }
  };

  private void endBillingClientConnection() {
    if (billingClient != null) {
      try {
        billingClient.endConnection();
        billingClient = null;
      } catch (Exception ignored) {}
    }
  }
}
