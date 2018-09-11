package com.dooboolab.flutterinapppurchase;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

import com.amazon.device.iap.PurchasingListener;
import com.amazon.device.iap.PurchasingService;
import com.amazon.device.iap.model.ProductDataResponse;
import com.amazon.device.iap.model.PurchaseResponse;
import com.amazon.device.iap.model.PurchaseUpdatesResponse;
import com.amazon.device.iap.model.UserDataResponse;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AmazonInappPurchasePlugin */
public class AmazonInappPurchasePlugin implements MethodCallHandler {
  public static Registrar reg;
  private final String TAG = "InappPurchasePlugin";
  private Result result = null;

  ServiceConnection mServiceConn = new ServiceConnection() {
    @Override public void onServiceDisconnected(ComponentName name) {
     // mService = null;
    }
    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
      // DONT KNOW WHAT IS NEEDED HERE

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
    } else if (call.method.equals("prepare")) {
      Intent intent = new Intent("com.amazon.device.iap.PurchasingService.BIND");
      intent.setPackage("com.amazon.venezia");

      try {
        reg.context().bindService(intent, mServiceConn, Context.BIND_AUTO_CREATE);
        PurchasingService.registerListener(reg.context(), purchasesUpdatedListener);
        result.success("Billing client ready");
      } catch (Exception e) {
        result.error(call.method, "Call endConnection method if you want to start over.", e.getMessage());
      }
    } else if (call.method.equals("endConnection")) {
      try {
        result.success("Billing client has ended.");
      } catch (Exception e) {
        result.error(call.method, e.getMessage(), "");
      }
    } else if (call.method.equals("consumeAllItems")) {
      result.notImplemented();
    } else if (call.method.equals("getItemsByType")) {
      System.err.println("getItemsByType");
      String type = call.argument("type");
      ArrayList<String> skus = call.argument("skus");

      final Set<String> productSkus = new HashSet<>();
      for (int i = 0; i < skus.size(); i++) {
        System.err.println("Adding "+skus.get(i));
        productSkus.add(skus.get(i));
      }
      PurchasingService.getProductData(productSkus);

    } else if (call.method.equals("getAvailableItemsByType")) {
      // NEED TO IMPLEMENT
      result.notImplemented();
    } else if (call.method.equals("getPurchaseHistoryByType")) {
      result.notImplemented();
    } else if (call.method.equals("buyItemByType")) {
      // NEED TO IMPLEMENT
      result.notImplemented();
    } else if (call.method.equals("consumeProduct")) {
      result.notImplemented();
    } else {
      result.notImplemented();
    }
  }

  private PurchasingListener purchasesUpdatedListener = new PurchasingListener() {
    @Override
    public void onUserDataResponse(UserDataResponse userDataResponse) {
      System.err.println("oudr");
    }

    @Override
    public void onProductDataResponse(ProductDataResponse productDataResponse) {
      System.err.println("opdr");
    }

    @Override
    public void onPurchaseResponse(PurchaseResponse purchaseResponse) {
      System.err.println("opr");
    }

    @Override
    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse purchaseUpdatesResponse) {
      System.err.println("opudr");
    }
  };

/*
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
          item.put("transactionReceipt", purchase.getPurchaseToken());
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
  */
}
