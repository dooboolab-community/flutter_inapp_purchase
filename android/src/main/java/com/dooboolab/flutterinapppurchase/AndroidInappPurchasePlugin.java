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
    final String type = call.argument("type");
    final ArrayList<String> skuList = call.argument("skus");
    final String sku = call.argument("sku");
    final Integer prorationMode = call.argument("prorationMode");
    final String obfuscatedAccountId = call.argument("obfuscatedAccountId");
    final String obfuscatedProfileId = call.argument("obfuscatedProfileId");
    final String oldSku = call.argument("oldSku");
    final String purchaseToken = call.argument("purchaseToken");
    final String token = call.argument("token");

    switch (call.method){
      case "getPlatformVersion":
        getPlatformVersion(result);
        break;
      case "initConnection":
        initConnection(result);
        break;
      case "endConnection":
        endConnection(result);
        break;
      case "consumeAllItems":
        consumeAllItems(result);
        break;
      case "getItemsByType":
        if(type == null || skuList == null) {
          result.error(call.method, "E_WRONG_PARAMS", "type and skuList must be NonNullable for method");
          return;
        }
        getItemsByType(result,skuList,type);
        break;
      case "getAvailableItemsByType":
        if(type == null) {
          result.error(call.method, "E_WRONG_PARAMS", "type must be NonNullable for method");
          return;
        }
        getItemsByType(result,type);
        break;
      case "getPurchaseHistoryByType":
        if(type == null) {
          result.error(call.method, "E_WRONG_PARAMS", "type must be NonNullable for method");
          return;
        }
        getPurchaseHistoryByType(result,type);
        break;
      case "buyItemByType":
        if(type == null || sku == null || prorationMode == null) {
          result.error(call.method, "E_WRONG_PARAMS", "type and sku must be NonNullable for method");
          return;
        }
        buyItemByType(
                result,
                sku,
                type,
                prorationMode,
                obfuscatedAccountId,
                obfuscatedProfileId,
                oldSku,
                purchaseToken
        );
        break;
      case "acknowledgePurchase":
        if(token == null) {
          result.error(call.method, "E_WRONG_PARAMS", "token must be NonNullable for method");
          return;
        }
        acknowledgePurchase(result,token);
        break;
      case "consumeProduct":
        if(token == null) {
          result.error(call.method, "E_WRONG_PARAMS", "token must be NonNullable for method");
          return;
        }
        consumeProduct(result,token);
        break;
      default:
        result.notImplemented();
    }
  }

  private final PurchasesUpdatedListener purchasesUpdatedListener = new PurchasesUpdatedListener() {
    @Override
    public void onPurchasesUpdated(BillingResult billingResult, @Nullable List<Purchase> purchases) {
      if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
        final HashMap<String,Object> resultMap = FlutterEntitiesBuilder.buildBillingResultMap(billingResult);
        channel.invokeMethod("purchase-error", resultMap);
        return;
      }

      if (purchases == null){
        String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
        final HashMap<String,Object> resultMap = FlutterEntitiesBuilder.buildBillingResultMap(billingResult,errorData[0],"purchases returns null");
        channel.invokeMethod("purchase-error", resultMap);
        return;
      }

      for (Purchase purchase : purchases) {
        channel.invokeMethod("purchase-updated", FlutterEntitiesBuilder.buildPurchaseMap(purchase));
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


  private void getPlatformVersion(final @NonNull Result result){
    try {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } catch(IllegalStateException e){
      result.error("getPlatformVersion", e.getMessage(), e.getLocalizedMessage());
    }
  }

  /*
   * initConnection
   */
  private void initConnection(final @NonNull Result result){
    if (billingClient != null) {
      result.success("Already started. Call endConnection method if you want to start over.");
      return;
    }

    billingClient = BillingClient.newBuilder(context).setListener(purchasesUpdatedListener)
            .enablePendingPurchases()
            .build();

    billingClient.startConnection(new BillingClientStateListener() {
      private boolean isSetUp = false;

      @Override
      public void onBillingSetupFinished(@NonNull BillingResult billingResult) {
        int responseCode = billingResult.getResponseCode();

        if (isSetUp) return;

        HashMap<String, Boolean> item = new HashMap<>();
        if (responseCode == BillingClient.BillingResponseCode.OK) {
          item.put("connected", true);
          channel.invokeMethod("connection-updated", item);
          result.success("Billing client ready");
        } else {
          item.put("connected", false);
          channel.invokeMethod("connection-updated", item);
          result.error("initConnection", "responseCode: " + responseCode, "");
        }

        isSetUp = true;
      }

      @Override
      public void onBillingServiceDisconnected() {
        HashMap<String,Boolean> item = new HashMap<>();
        item.put("connected", false);
        channel.invokeMethod("connection-updated", item);
        isSetUp = false;
      }
    });
  }


  /*
   * endConnection
   */
  private void endConnection(final @NonNull Result result){
    if (billingClient != null) {
      try {
        billingClient.endConnection();
        billingClient = null;
        result.success("Billing client has ended.");
      } catch (Exception e) {
        result.error("endConnection", e.getMessage(), "");
      }
    }
  }

  /*
   * consumeAllItems
   */
  private void consumeAllItems(final @NonNull Result result){
    try {
      final ArrayList<String> array = new ArrayList<>();
      Purchase.PurchasesResult purchasesResult = billingClient.queryPurchases(BillingClient.SkuType.INAPP);
      if (purchasesResult == null) {
        result.error("consumeAllItems","refreshItem", "No results for query");
        return;
      }
      final List<Purchase> purchases = purchasesResult.getPurchasesList();
      if (purchases == null || purchases.size() == 0) {
        result.error("consumeAllItems", "refreshItem", "No purchases found");
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
      result.error("consumeAllItems", err.getMessage(), "");
    }
  }

  /*
   * getItemsByType
   * arguments: type, skus
   */
  private void getItemsByType(final @NonNull Result result, final @NonNull ArrayList<String> skuList,final @NonNull String type){
    if (billingClient == null || !billingClient.isReady()) {
      result.error("getItemsByType", "IAP not prepared. Check if Google Play service is available.", "");
      return;
    }

    SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
    params.setSkusList(skuList).setType(type);

    billingClient.querySkuDetailsAsync(params.build(), new SkuDetailsResponseListener() {
      @Override
      public void onSkuDetailsResponse(@NonNull BillingResult billingResult, List<SkuDetails> skuDetailsList) {
        int responseCode = billingResult.getResponseCode();
        if (responseCode != BillingClient.BillingResponseCode.OK) {
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          result.error("getItemsByType", errorData[0], errorData[1]);
          return;
        }

        for (SkuDetails sku : skuDetailsList) {
          if (!skus.contains(sku)) skus.add(sku);
        }


        ArrayList<HashMap<String, Object>> items = new ArrayList<>();
        for (SkuDetails skuDetails : skuDetailsList) {
          items.add(FlutterEntitiesBuilder.buildSkuDetailsMap(skuDetails));
        }
        result.success(items);
      }
    });
  }

  /*
   * getAvailableItemsByType
   * arguments: type
   */
  private void getItemsByType(final @NonNull Result result, final @NonNull String type){
    if (billingClient == null || !billingClient.isReady()) {
      result.error("getItemsByType", "IAP not prepared. Check if Google Play service is available.", "");
      return;
    }

    final Purchase.PurchasesResult purchasesResult = billingClient.queryPurchases(type.equals("subs") ? BillingClient.SkuType.SUBS : BillingClient.SkuType.INAPP);
    final List<Purchase> purchases = purchasesResult.getPurchasesList();

    ArrayList<HashMap<String, Object>> items = new ArrayList<>();

    if (purchases != null) {
      for (Purchase purchase : purchases) {
        items.add(FlutterEntitiesBuilder.buildPurchaseMap(purchase));
      }
    }

    result.success(items);
  }

  /*
   * getPurchaseHistoryByType
   * arguments: type
   */
  private void getPurchaseHistoryByType(final @NonNull Result result, final @NonNull String type){
    billingClient.queryPurchaseHistoryAsync(type.equals("subs") ? BillingClient.SkuType.SUBS : BillingClient.SkuType.INAPP, new PurchaseHistoryResponseListener() {
      @Override
      public void onPurchaseHistoryResponse(@NonNull BillingResult billingResult, List<PurchaseHistoryRecord> purchaseHistoryRecordList) {
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          result.error("getPurchaseHistoryByType", errorData[0], errorData[1]);
          return;
        }

        ArrayList<HashMap<String, Object>> items = new ArrayList<>();
        for (PurchaseHistoryRecord record : purchaseHistoryRecordList) {
          items.add(FlutterEntitiesBuilder.buildPurchaseHistoryRecordMap(record));
        }

        result.success(items);
      }
    });
  }

  /*
   * buyItemByType
   * arguments: type, obfuscatedAccountId, obfuscatedProfileId, sku, oldSku, prorationMode, purchaseToken
   */
  private void buyItemByType(
          final @NonNull Result result,
          final @NonNull String sku,
          final @NonNull String type,
          final int prorationMode,
          final String obfuscatedAccountId,
          final String obfuscatedProfileId,
          final String oldSku,
          final String purchaseToken
  ){
    if (billingClient == null || !billingClient.isReady()) {
      result.error("buyItemByType", "IAP not prepared. Check if Google Play service is available.", "");
      return;
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

    // Releases async invokeMethod on Flutter side
    result.success(null);
  }

  /*
   * acknowledgePurchase (For non-consumable purchases)
   * arguments: token
   */
  private void acknowledgePurchase(final @NonNull Result result, final @NonNull String token){
    if (billingClient == null || !billingClient.isReady()) {
      result.error("acknowledgePurchase", "IAP not prepared. Check if Google Play service is available.", "");
      return;
    }


    AcknowledgePurchaseParams acknowledgePurchaseParams =
            AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(token)
                    .build();

    billingClient.acknowledgePurchase(acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener() {
      @Override
      public void onAcknowledgePurchaseResponse(@NonNull BillingResult billingResult) {
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          result.error("acknowledgePurchase", errorData[0], errorData[1]);
        } else {
          final HashMap<String,Object> resultMap = FlutterEntitiesBuilder.buildBillingResultMap(billingResult);
          result.success(resultMap);
        }
      }
    });
  }

  /*
   * consumeProduct (For consumable purchases)
   * arguments: token
   */
  private void consumeProduct(final @NonNull Result result, final @NonNull String token){
    if (billingClient == null || !billingClient.isReady()) {
      result.error("consumeProduct", "IAP not prepared. Check if Google Play service is available.", "");
      return;
    }

    final ConsumeParams params = ConsumeParams.newBuilder()
            .setPurchaseToken(token)
            .build();

    billingClient.consumeAsync(params, new ConsumeResponseListener() {
      @Override
      public void onConsumeResponse(@NonNull BillingResult billingResult,@NonNull String purchaseToken) {
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
          String[] errorData = DoobooUtils.getInstance().getBillingResponseData(billingResult.getResponseCode());
          result.error("consumeProduct", errorData[0], errorData[1]);
        } else{
          final HashMap<String,Object> resultMap = FlutterEntitiesBuilder.buildBillingResultMap(billingResult);
          result.success(resultMap);
        }
      }
    });
  }



}
