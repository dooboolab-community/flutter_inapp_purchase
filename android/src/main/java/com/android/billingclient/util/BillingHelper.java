package com.android.billingclient.util;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import com.android.billingclient.api.BillingClient.BillingResponse;
import com.android.billingclient.api.Purchase;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONException;

/** Helper methods for billing client. */
public final class BillingHelper {
  // Keys for the responses from InAppBillingService
  public static final String RESPONSE_CODE = "RESPONSE_CODE";
  public static final String RESPONSE_GET_SKU_DETAILS_LIST = "DETAILS_LIST";
  public static final String RESPONSE_BUY_INTENT = "BUY_INTENT";
  // StringArrayList containing the list of SKUs
  public static final String RESPONSE_INAPP_ITEM_LIST = "INAPP_PURCHASE_ITEM_LIST";
  // StringArrayList containing the purchase information
  public static final String RESPONSE_INAPP_PURCHASE_DATA_LIST = "INAPP_PURCHASE_DATA_LIST";
  // StringArrayList containing the signatures of the purchase information
  public static final String RESPONSE_INAPP_SIGNATURE_LIST = "INAPP_DATA_SIGNATURE_LIST";
  public static final String INAPP_CONTINUATION_TOKEN = "INAPP_CONTINUATION_TOKEN";
  private static final String TAG = "BillingHelper";
  // Keys for Purchase data parsing
  private static final String RESPONSE_INAPP_PURCHASE_DATA = "INAPP_PURCHASE_DATA";
  private static final String RESPONSE_INAPP_SIGNATURE = "INAPP_DATA_SIGNATURE";

  /** Total number of cores of current device */
  public static int NUMBER_OF_CORES = Runtime.getRuntime().availableProcessors();

  /**
   * Logs a verbose message
   *
   * @param tag Tag to be used inside logging
   * @param msg Message to log
   */
  public static void logVerbose(String tag, String msg) {
    if (Log.isLoggable(tag, Log.VERBOSE)) {
      Log.v(tag, msg);
    }
  }

  /**
   * Logs a warning message
   *
   * @param tag Tag to be used inside logging
   * @param msg Message to log
   */
  public static void logWarn(String tag, String msg) {
    if (Log.isLoggable(tag, Log.WARN)) {
      Log.w(tag, msg);
    }
  }

  /** Retrieves a response code from the intent */
  @BillingResponse
  public static int getResponseCodeFromIntent(Intent intent, String tag) {
    if (intent == null) {
      logWarn(TAG, "Got null intent!");
      return BillingResponse.ERROR;
    } else {
      return getResponseCodeFromBundle(intent.getExtras(), tag);
    }
  }

  /** Retrieves a response code from the bundle */
  @BillingResponse
  public static int getResponseCodeFromBundle(Bundle bundle, String tag) {
    // Returning the error for null bundle
    if (bundle == null) {
      logWarn(tag, "Unexpected null bundle received!");
      return BillingResponse.ERROR;
    }
    // Getting the responseCode to report
    Object responseCode = bundle.get(RESPONSE_CODE);
    if (responseCode == null) {
      logVerbose(tag, "getResponseCodeFromBundle() got null response code, assuming OK");
      return BillingResponse.OK;
    } else if (responseCode instanceof Integer) {
      // noinspection WrongConstant
      return (Integer) responseCode;
    } else {
      logWarn(
          tag, "Unexpected type for bundle response code: " + responseCode.getClass().getName());
      return BillingResponse.ERROR;
    }
  }

  /**
   * Gets a purchase data and signature (or lists of them) from the Bundle and returns the
   * constructed list of {@link Purchase}
   *
   * @param bundle The bundle to parse
   * @return New Purchase instance with the data extracted from the provided intent
   */
  public static List<Purchase> extractPurchases(Bundle bundle) {
    if (bundle == null) {
      return null;
    }

    List<String> purchaseDataList = bundle.getStringArrayList(RESPONSE_INAPP_PURCHASE_DATA_LIST);
    List<String> dataSignatureList = bundle.getStringArrayList(RESPONSE_INAPP_SIGNATURE_LIST);

    List<Purchase> resultList = new ArrayList<>();

    // If there were no lists of data, try to find single purchase data inside the Bundle
    if (purchaseDataList == null || dataSignatureList == null) {
      BillingHelper.logWarn(TAG, "Couldn't find purchase lists, trying to find single data.");

      String purchaseData = bundle.getString(RESPONSE_INAPP_PURCHASE_DATA);
      String dataSignature = bundle.getString(RESPONSE_INAPP_SIGNATURE);

      Purchase tmpPurchase = extractPurchase(purchaseData, dataSignature);

      if (tmpPurchase == null) {
        BillingHelper.logWarn(TAG, "Couldn't find single purchase data as well.");
        return null;
      } else {
        resultList.add(tmpPurchase);
      }
    } else {
      for (int i = 0; (i < purchaseDataList.size() && i < dataSignatureList.size()); ++i) {
        Purchase tmpPurchase = extractPurchase(purchaseDataList.get(i), dataSignatureList.get(i));

        if (tmpPurchase != null) {
          resultList.add(tmpPurchase);
        }
      }
    }
    return resultList;
  }

  private static Purchase extractPurchase(String purchaseData, String signatureData) {

    if (purchaseData == null || signatureData == null) {
      BillingHelper.logWarn(TAG, "Received a bad purchase data.");
      return null;
    }

    Purchase purchase = null;
    try {
      purchase = new Purchase(purchaseData, signatureData);
    } catch (JSONException e) {
      BillingHelper.logWarn(TAG, "Got JSONException while parsing purchase data: " + e);
    }

    return purchase;
  }
}
