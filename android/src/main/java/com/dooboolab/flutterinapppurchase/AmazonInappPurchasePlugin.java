package com.dooboolab.flutterinapppurchase;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import com.amazon.device.iap.PurchasingListener;
import com.amazon.device.iap.PurchasingService;
import com.amazon.device.iap.model.Product;
import com.amazon.device.iap.model.ProductDataResponse;
import com.amazon.device.iap.model.ProductType;
import com.amazon.device.iap.model.PurchaseResponse;
import com.amazon.device.iap.model.PurchaseUpdatesResponse;
import com.amazon.device.iap.model.UserDataResponse;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.NumberFormat;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
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
  private PurchasingService mService;
  private Result result = null;

  ServiceConnection mServiceConn = new ServiceConnection() {
    @Override public void onServiceDisconnected(ComponentName name) {
      mService = null;
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
      PurchasingService.getUserData();
      PurchasingService.getPurchaseUpdates(true);

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
      Log.d(TAG, "oudr="+userDataResponse.toString());
    }

    @Override
    public void onProductDataResponse(ProductDataResponse response) {
      Log.d(TAG, "opdr="+response.toString());
      final ProductDataResponse.RequestStatus status = response.getRequestStatus();
      Log.d(TAG, "onProductDataResponse: RequestStatus (" + status + ")");

      switch (status) {
        case SUCCESSFUL:
          Log.d(TAG, "onProductDataResponse: successful.  The item data map in this response includes the valid SKUs");

          final Map<String, Product> productData = response.getProductData();
          //Log.d(TAG, "productData="+productData.toString());

          final Set<String> unavailableSkus = response.getUnavailableSkus();
          Log.d(TAG, "onProductDataResponse: " + unavailableSkus.size() + " unavailable skus");
          Log.d(TAG, "unavailableSkus="+unavailableSkus.toString());
          JSONArray items = new JSONArray();
          try {
            for (Map.Entry<String, Product> skuDetails : productData.entrySet()) {
              Product product=skuDetails.getValue();
              NumberFormat format = NumberFormat.getCurrencyInstance();

              Number number;
              try {
                number = format.parse(product.getPrice());
              } catch (ParseException e) {
                result.error(TAG, "Price Parsing error", e.getMessage());
                return;
              }
              JSONObject item = new JSONObject();
              item.put("productId", product.getSku());
              item.put("price", number.toString());
              item.put("currency", "CAD");
              ProductType productType = product.getProductType();
              switch (productType) {
                case ENTITLED:
                  item.put("type", "inapp");
                  break;
              }
              item.put("localizedPrice", product.getPrice());
              item.put("title", product.getTitle());
              item.put("description", product.getDescription());
              item.put("introductoryPrice", "");
              item.put("subscriptionPeriodAndroid", "");
              item.put("freeTrialPeriodAndroid", "");
              item.put("introductoryPriceCyclesAndroid", "");
              item.put("introductoryPricePeriodAndroid", "");
              System.err.println("opdr Putting "+item.toString());
              items.put(item);
            }
            //System.err.println("Sending "+items.toString());
            result.success(items.toString());
          } catch (JSONException e) {
            result.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.getMessage());
          }
          break;
        case FAILED:
          result.error(TAG,"FAILED",null);
        case NOT_SUPPORTED:
          Log.d(TAG, "onProductDataResponse: failed, should retry request");
          result.error(TAG,"NOT_SUPPORTED",null);
          break;
      }
    }

    @Override
    public void onPurchaseResponse(PurchaseResponse purchaseResponse) {
      Log.d(TAG, "opr="+purchaseResponse.toString());
    }

    @Override
    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse purchaseUpdatesResponse) {
      Log.d(TAG, "opudr="+purchaseUpdatesResponse.toString());
    }
  };
}
