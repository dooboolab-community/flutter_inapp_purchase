package com.dooboolab.flutterinapppurchase;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.amazon.device.iap.PurchasingListener;
import com.amazon.device.iap.PurchasingService;
import com.amazon.device.iap.model.FulfillmentResult;
import com.amazon.device.iap.model.Product;
import com.amazon.device.iap.model.ProductDataResponse;
import com.amazon.device.iap.model.PurchaseResponse;
import com.amazon.device.iap.model.PurchaseUpdatesResponse;
import com.amazon.device.iap.model.Receipt;
import com.amazon.device.iap.model.RequestId;
import com.amazon.device.iap.model.UserDataResponse;

import java.text.NumberFormat;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** AmazonInappPurchasePlugin */
public class AmazonInappPurchasePlugin implements MethodCallHandler {

  private final String TAG = "InappPurchasePlugin";
  private Result result = null;
  private MethodChannel channel;
  private Context context;
  private Activity activity;

  public void setContext(Context context) {
    this.context = context;
  }

  public void setActivity(Activity activity) {
    this.activity = activity;
  }

  public void setChannel(MethodChannel channel) {
    this.channel = channel;
  }

  @Override
  public void onMethodCall(final @NonNull MethodCall call, final @NonNull Result result) {
    this.result=result;
    try {
      PurchasingService.registerListener(context, purchasesUpdatedListener);
    } catch (Exception e) {
      result.error(call.method, "Call endConnection method if you want to start over.", e.getMessage());
    }

    if (call.method.equals("getPlatformVersion")) {
      try {
        result.success("Android " + android.os.Build.VERSION.RELEASE);
      } catch(IllegalStateException e){
        e.printStackTrace();
      }
    } else if (call.method.equals("initConnection")) {
      PurchasingService.getUserData();
      result.success("Billing client ready");
    } else if (call.method.equals("endConnection")) {
      result.success("Billing client has ended.");
    } else if (call.method.equals("consumeAllItems")) {
      // consumable is a separate type in amazon
      result.error("E_NO_OP_IN_AMAZON","no-ops in amazon",null);
    } else if (call.method.equals("getItemsByType")) {
      Log.d(TAG, "getItemsByType");
      String type = call.argument("type");
      ArrayList<String> skus = call.argument("skus");

      final Set<String> productSkus = new HashSet<>();
      for (int i = 0; i < skus.size(); i++) {
        Log.d(TAG, "Adding "+skus.get(i));
        productSkus.add(skus.get(i));
      }
      PurchasingService.getProductData(productSkus);

      final ArrayList<HashMap<String, Object>> list = new ArrayList<>();
      result.success(list);
    } else if (call.method.equals("getAvailableItemsByType")) {
      String type = call.argument("type");
      Log.d(TAG, "gaibt="+type);

      final ArrayList<HashMap<String, Object>> list = new ArrayList<>();
      // NOTE: getPurchaseUpdates doesnt return Consumables which are FULFILLED
      if(type.equals("inapp")) {
          PurchasingService.getPurchaseUpdates(true);
          result.success(list);
      } else if(type.equals("subs")) {
        // Subscriptions are retrieved during inapp, so we just return empty list
        result.success(list);
      } else {
        result.notImplemented();
      }
    } else if (call.method.equals("getPurchaseHistoryByType")) {
      final ArrayList<HashMap<String, Object>> list = new ArrayList<>();
      // No equivalent
      result.success(list);
    } else if (call.method.equals("buyItemByType")) {
      final String type = call.argument("type");
      final String obfuscatedAccountId = call.argument("obfuscatedAccountId");
      final String obfuscatedProfileId = call.argument("obfuscatedProfileId");
      final String sku = call.argument("sku");
      final String oldSku = call.argument("oldSku");
      final int prorationMode = call.argument("prorationMode");

      Log.d(TAG, "type="+type+"||sku="+sku+"||oldsku="+oldSku);
      final RequestId requestId = PurchasingService.purchase(sku);
      Log.d(TAG, "resid="+requestId.toString());

      result.success(null);
    } else if (call.method.equals("consumeProduct")) {
      // consumable is a separate type in amazon
      result.error("E_NO_OP_IN_AMAZON","no-ops in amazon",null);
    } else {
      result.notImplemented();
    }
  }

  private PurchasingListener purchasesUpdatedListener = new PurchasingListener() {
    @Override
    public void onUserDataResponse(UserDataResponse userDataResponse) {
      Log.d(TAG, "oudr="+userDataResponse.toString());
    }

    // getItemsByType
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
          ArrayList<HashMap<String,Object>> items = new ArrayList<>();

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

            final HashMap<String,Object> item = FlutterEntitiesBuilder.buildSkuDetailsMap(product);
            Log.d(TAG, "opdr Putting "+item.toString());
            items.add(item);
          }
          result.success(items);

          break;
        case FAILED:
          result.error(TAG,"FAILED",null);
        case NOT_SUPPORTED:
          Log.d(TAG, "onProductDataResponse: failed, should retry request");
          result.error(TAG,"NOT_SUPPORTED",null);
          break;
      }
    }

    // buyItemByType
    @Override
    public void onPurchaseResponse(PurchaseResponse response) {
      Log.d(TAG, "opr="+response.toString());
      final PurchaseResponse.RequestStatus status = response.getRequestStatus();
      switch(status) {
        case SUCCESSFUL:
          Receipt receipt = response.getReceipt();
          PurchasingService.notifyFulfillment(receipt.getReceiptId(), FulfillmentResult.FULFILLED);

          final HashMap<String,Object> item = FlutterEntitiesBuilder.buildPurchaseMap(receipt);
          Log.d(TAG, "opr Putting "+item.toString());
          result.success(item);
          channel.invokeMethod("purchase-updated", item);

          break;
        case FAILED:
          result.error(TAG, "buyItemByType", "billingResponse is not ok: " + status);
          break;
      }
    }

    // getAvailableItemsByType
    @Override
    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse response) {
      Log.d(TAG, "opudr="+response.toString());
      final PurchaseUpdatesResponse.RequestStatus status = response.getRequestStatus();

      switch(status) {
        case SUCCESSFUL:
          ArrayList<HashMap<String,Object>> items = new ArrayList<>();

          List<Receipt> receipts = response.getReceipts();
          for(Receipt receipt : receipts) {
            final HashMap<String,Object> item = FlutterEntitiesBuilder.buildPurchaseMap(receipt);
            Log.d(TAG, "opudr Putting "+item.toString());
            items.add(item);
          }
          result.success(items);

          break;
        case FAILED:
          result.error(TAG,"FAILED",null);
          break;
        case NOT_SUPPORTED:
          Log.d(TAG, "onPurchaseUpdatesResponse: failed, should retry request");
          result.error(TAG,"NOT_SUPPORTED",null);
          break;
      }
    }
  };

}
