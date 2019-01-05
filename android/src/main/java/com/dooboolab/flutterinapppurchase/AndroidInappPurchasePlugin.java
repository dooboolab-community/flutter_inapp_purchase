package com.dooboolab.flutterinapppurchase;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.support.annotation.Nullable;
import android.util.Log;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchaseHistoryResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;
import com.android.vending.billing.IInAppBillingService;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AndroidInappPurchasePlugin */
public class AndroidInappPurchasePlugin implements MethodCallHandler {
  public static Registrar reg;
  private final String TAG = "InappPurchasePlugin";
  private IInAppBillingService mService;
  private BillingClient mBillingClient;
  private Result result = null;

  ServiceConnection mServiceConn = new ServiceConnection() {
    @Override public void onServiceDisconnected(ComponentName name) {
      mService = null;
    }
    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
      mService = IInAppBillingService.Stub.asInterface(service);
    }
  };

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_inapp");
    channel.setMethodCallHandler(new FlutterInappPurchasePlugin());
    reg = registrar;
  }

  @Override
  public void onMethodCall(final MethodCall call, final Result result) {
    if (call.method.equals("getPlatformVersion")) {
      try {
        result.success("Android " + android.os.Build.VERSION.RELEASE);
      } catch(IllegalStateException e){
        e.printStackTrace();
      }
    }

    /*
     * prepare
     */
    else if (call.method.equals("prepare")) {
      Intent intent = new Intent("com.android.vending.billing.InAppBillingService.BIND");
      // This is the key line that fixed everything for me
      intent.setPackage("com.android.vending");

      if (mBillingClient != null) {
        try{
          result.success("Already started. Call endConnection method if you want to start over.");
        } catch(IllegalStateException e){
          e.printStackTrace();
        }
        return;
      }

      try {
        reg.context().bindService(intent, mServiceConn, Context.BIND_AUTO_CREATE);
        mBillingClient = BillingClient.newBuilder(reg.context()).setListener(purchasesUpdatedListener).build();
        mBillingClient.startConnection(new BillingClientStateListener() {
          @Override
          public void onBillingSetupFinished(@BillingClient.BillingResponse int responseCode) {
            if (responseCode == BillingClient.BillingResponse.OK) {
              // The billing client is ready.
              try {
                result.success("Billing client ready");
              } catch(IllegalStateException e){
                e.printStackTrace();
              }
            } else {
              try {
                result.error(call.method, "responseCode: " + responseCode, "");
              } catch(IllegalStateException e){
                e.printStackTrace();
              }
            }
          }

          @Override
          public void onBillingServiceDisconnected() {
            // Try to restart the connection on the next request to
            // Google Play by calling the startConnection() method.
            Log.d(TAG, "billing client disconnected");
            // mBillingClient.startConnection(this);
          }
        });
      } catch (Exception e) {
        result.error(call.method, "Call endConnection method if you want to start over.", e.getMessage());
      }
    }

    /*
     * endConnection
     */
    else if (call.method.equals("endConnection")) {
      try {
        mBillingClient.endConnection();
        mBillingClient = null;
        result.success("Billing client has ended.");
      } catch (Exception e) {
        result.error(call.method, e.getMessage(), "");
      }
    }

    /*
     * consumeAllItems
     */
    else if (call.method.equals("consumeAllItems")) {
      try {
        Bundle ownedItems = mService.getPurchases(3, reg.context().getPackageName(), "inapp", null);
        int response = ownedItems.getInt("RESPONSE_CODE");
        if (response == 0) {
          ArrayList purchaseDataList = ownedItems.getStringArrayList("INAPP_PURCHASE_DATA_LIST");
          String[] tokens = new String[purchaseDataList.size()];
          for (int i = 0; i < purchaseDataList.size(); ++i) {
            String purchaseData = (String) purchaseDataList.get(i);
            JSONObject jo = new JSONObject(purchaseData);
            tokens[i] = jo.getString("purchaseToken");
            // Consume all remainingTokens
            mService.consumePurchase(3, reg.context().getPackageName(), tokens[i]);
          }
          result.success("All items have been consumed");
        }
      } catch (Exception e) {
        result.error(call.method, e.getMessage(), "");
      }
    }

    /*
     * getItemsByType
     * arguments: type, skus
     */
    else if (call.method.equals("getItemsByType")) {
      if (mService == null || mBillingClient == null) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      String type = call.argument("type");
      ArrayList<String> skus = call.argument("skus");


      ArrayList<String> skusList = new ArrayList<>();

      for (int i = 0; i < skus.size(); i++) {
        skusList.add(skus.get(i));
      }

      SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
      params.setSkusList(skusList).setType(type);
      mBillingClient.querySkuDetailsAsync(params.build(),
          new SkuDetailsResponseListener() {
            @Override
            public void onSkuDetailsResponse(int responseCode, List<SkuDetails> skuDetailsList) {
              Log.d(TAG, "responseCode: " + responseCode);
              JSONArray items = new JSONArray();
              if (responseCode == BillingClient.BillingResponse.OK) {
                try {
                  for (SkuDetails skuDetails : skuDetailsList) {
                    JSONObject item = new JSONObject();
                    item.put("productId", skuDetails.getSku());
                    item.put("price", String.format(Locale.ENGLISH, "%.02f", skuDetails.getPriceAmountMicros() / 1000000f));
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
                    items.put(item);
                  }
                } catch (JSONException e) {
                  result.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.getMessage());
                }
                result.success(items.toString());
              }
              else {
                result.error(TAG, call.method, "Billing response is not ok");
              }
            }
          }
      );
    }

    /*
     * getAvailableItemsByType
     * arguments: type
     */
    else if (call.method.equals("getAvailableItemsByType")) {
      if (mService == null) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      Bundle availableItems;
      String type = call.argument("type");
      try {
        availableItems = mService.getPurchases(3, reg.context().getPackageName(), type, null);
      } catch (RemoteException e) {
        result.error(call.method, e.getMessage(), "");
        return;
      }

      int responseCode = availableItems.getInt("RESPONSE_CODE");

      JSONArray items = new JSONArray();

      ArrayList<String> purchaseDataList = availableItems.getStringArrayList("INAPP_PURCHASE_DATA_LIST");
      ArrayList<String> signatureDataList = availableItems.getStringArrayList("INAPP_DATA_SIGNATURE_LIST");

      if (responseCode == BillingClient.BillingResponse.OK && purchaseDataList != null) {

        for (int i = 0; i < purchaseDataList.size(); i++) {
          try {
            String data = purchaseDataList.get(i);
            String signature = signatureDataList.get(i);

            JSONObject json = new JSONObject(data);
            JSONObject item = new JSONObject();
            item.put("productId", json.getString("productId"));
            if (json.has("orderId")) {
              item.put("transactionId", json.getString("orderId"));
            }
            item.put("transactionDate", json.getString("purchaseTime"));
            if (json.has("originalJson")) {
              item.put("transactionReceipt", json.getString("originalJson"));
            }
            item.put("dataAndroid", data);
            item.put("signatureAndroid", signature);
            item.put("purchaseToken", json.getString("purchaseToken"));

            if (type.equals(BillingClient.SkuType.SUBS)) {
              item.put("autoRenewingAndroid", json.getBoolean("autoRenewing"));
            }
            items.put(item);
          } catch (JSONException e) {
            result.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.getMessage());
          }
        }
        result.success(items.toString());
      }
      else {
        result.error(TAG, "Item not available", "responseCode: " + responseCode);
      }
    }

    /*
     * getPurchaseHistoryByType
     * arguments: type
     */
    else if (call.method.equals("getPurchaseHistoryByType")) {
      if (mService == null || mBillingClient == null) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String type = call.argument("type");

      mBillingClient.queryPurchaseHistoryAsync(type, new PurchaseHistoryResponseListener() {
        @Override
        public void onPurchaseHistoryResponse(@BillingClient.BillingResponse int responseCode,
                                              List<Purchase> purchasesList) {
          Log.d(TAG, "responseCode: " + responseCode);

          if (purchasesList != null && responseCode == BillingClient.BillingResponse.OK) {
            Log.d(TAG, purchasesList.toString());

            JSONArray items = new JSONArray();

            try {
              for (Purchase purchase : purchasesList) {
                JSONObject item = new JSONObject();
                item.put("productId", purchase.getSku());
                item.put("transactionId", purchase.getOrderId());
                item.put("transactionDate", String.valueOf(purchase.getPurchaseTime()));
                item.put("transactionReceipt", purchase.getOriginalJson());
                item.put("purchaseToken", purchase.getPurchaseToken());
                item.put("dataAndroid", purchase.getOriginalJson());
                item.put("signatureAndroid", purchase.getSignature());

                if (type.equals(BillingClient.SkuType.SUBS)) {
                  item.put("autoRenewingAndroid", purchase.isAutoRenewing());
                }

                items.put(item);
              }
            } catch (JSONException je) {
              result.error(TAG, "JSON_PARSE_ERROR", je.getMessage());
            }
            result.success(items.toString());
          } else {
            result.error(TAG, "getAvailableItemsByType", "billingResponse is not ok: " + responseCode);
          }
        }
      });
    }

    /*
     * buyItemByType
     * arguments: type, sku, oldSku
     */
    else if (call.method.equals("buyItemByType")) {
      this.result = result;
      if (mService == null || mBillingClient == null) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String type = call.argument("type");
      final String sku = call.argument("sku");
      final String oldSku = call.argument("oldSku");

      BillingFlowParams.Builder builder = BillingFlowParams.newBuilder();

      if (type.equals(BillingClient.SkuType.SUBS) && oldSku != null && !oldSku.isEmpty()) {
        // Subscription upgrade/downgrade
        builder.addOldSku(oldSku);
      }

      BillingFlowParams flowParams = builder.setSku(sku)
          .setType(type)
          .build();

      int responseCode = mBillingClient.launchBillingFlow(reg.activity(),flowParams);
      if (responseCode != BillingClient.BillingResponse.OK) {
        result.error(TAG, "buyItemByType", "billingResponse is not ok: " + responseCode);
      }
    }

    /*
     * consumeProduct
     * arguments: type
     */
    else if (call.method.equals("consumeProduct")) {
      if (mService == null || mBillingClient == null) {
        result.error(call.method, "IAP not prepared. Check if Google Play service is available.", "");
        return;
      }

      final String token = call.argument("token");

      mBillingClient.consumeAsync(token, new ConsumeResponseListener() {
        @Override
        public void onConsumeResponse(@BillingClient.BillingResponse int responseCode, String outToken) {
          if (responseCode == BillingClient.BillingResponse.OK) {
            Log.d(TAG, "consume responseCode: " + responseCode);
            result.success("Consumed: " + responseCode);
          }
          else {
            result.error(TAG, "consumeProduct", "consumeResponse is not ok: " + responseCode);
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
    public void onPurchasesUpdated(int responseCode, @Nullable List<Purchase> purchases) {
      Log.d(TAG, "Purchase Updated Listener");
      Log.d(TAG, "responseCode: " + responseCode);

      if (responseCode == BillingClient.BillingResponse.OK && purchases != null) {
        Purchase purchase = purchases.get(0);

        JSONObject item = new JSONObject();
        try {
          item.put("productId", purchase.getSku());
          item.put("transactionId", purchase.getOrderId());
          item.put("transactionDate", String.valueOf(purchase.getPurchaseTime()));
          item.put("transactionReceipt", purchase.getOriginalJson());
          item.put("purchaseToken", purchase.getPurchaseToken());
          item.put("dataAndroid", purchase.getOriginalJson());
          item.put("signatureAndroid", purchase.getSignature());
          item.put("autoRenewingAndroid", purchase.isAutoRenewing());
        } catch (JSONException je) {
          if (result != null) {
            result.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", je.getMessage());
            result = null;
          }
        }
        if (result != null) {
          result.success(item.toString());
          result = null;
        }
      } else {
        if (result != null) {
          result.error(TAG, "purchase error", "responseCode: " + responseCode);
          result = null;
        }
      }
    }
  };
}
