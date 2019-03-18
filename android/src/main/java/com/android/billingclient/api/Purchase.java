package com.android.billingclient.api;

import android.text.TextUtils;

import com.android.billingclient.api.BillingClient.BillingResponse;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

/** Represents an in-app billing purchase. */
public class Purchase {

  private final String mOriginalJson;
  private final String mSignature;
  private final JSONObject mParsedJson;

  public Purchase(String jsonPurchaseInfo, String signature) throws JSONException {
    mOriginalJson = jsonPurchaseInfo;
    mSignature = signature;
    mParsedJson = new JSONObject(mOriginalJson);
  }

  /**
   * Returns an unique order identifier for the transaction. This identifier corresponds to the
   * Google payments order ID.
   */
  public String getOrderId() {
    return mParsedJson.optString("orderId");
  }

  /** Returns the application package from which the purchase originated. */
  public String getPackageName() {
    return mParsedJson.optString("packageName");
  }

  /** Returns the developerPayload from which the purchase originated. */
  public String getDeveloperPayload() {
      return mParsedJson.optString("developerPayload");
  }

  /** Returns the product Id. */
  public String getSku() {
    return mParsedJson.optString("productId");
  }

  /** Returns the time the product was purchased, in milliseconds since the epoch (Jan 1, 1970). */
  public long getPurchaseTime() {
    return mParsedJson.optLong("purchaseTime");
  }

  /** Returns a token that uniquely identifies a purchase for a given item and user pair. */
  public String getPurchaseToken() {
    return mParsedJson.optString("token", mParsedJson.optString("purchaseToken"));
  }

  /**
   * Indicates whether the subscription renews automatically. If true, the subscription is active,
   * and will automatically renew on the next billing date. If false, indicates that the user has
   * canceled the subscription. The user has access to subscription content until the next billing
   * date and will lose access at that time unless they re-enable automatic renewal (or manually
   * renew, as described in Manual Renewal). If you offer a grace period, this value remains set to
   * true for all subscriptions, as long as the grace period has not lapsed. The next billing date
   * is extended dynamically every day until the end of the grace period or until the user fixes
   * their payment method.
   */
  public boolean isAutoRenewing() {
    return mParsedJson.optBoolean("autoRenewing");
  }

  /** Returns a String in JSON format that contains details about the purchase order. */
  public String getOriginalJson() {
    return mOriginalJson;
  }

  /**
   * Returns String containing the signature of the purchase data that was signed with the private
   * key of the developer. The data signature uses the RSASSA-PKCS1-v1_5 scheme.
   */
  public String getSignature() {
    return mSignature;
  }

  @Override
  public String toString() {
    return "Purchase. Json: " + mOriginalJson;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }

    if (!(o instanceof Purchase)) {
      return false;
    }

    Purchase purchase = (Purchase) o;

    return TextUtils.equals(mOriginalJson, purchase.getOriginalJson())
        && TextUtils.equals(mSignature, purchase.getSignature());
  }

  @Override
  public int hashCode() {
    return mOriginalJson.hashCode();
  }

  /** Result list and code for queryPurchases method */
  public static class PurchasesResult {
    private List<Purchase> mPurchaseList;
    @BillingResponse private int mResponseCode;

    PurchasesResult(@BillingResponse int responseCode, List<Purchase> purchasesList) {
      this.mPurchaseList = purchasesList;
      this.mResponseCode = responseCode;
    }

    /** Returns the response code of the operation. */
    @BillingResponse
    public int getResponseCode() {
      return mResponseCode;
    }

    /** Returns the list of {@link Purchase}. */
    public List<Purchase> getPurchasesList() {
      return mPurchaseList;
    }
  }
}
