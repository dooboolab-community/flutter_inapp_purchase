package com.android.billingclient.api;

import android.text.TextUtils;
import com.android.billingclient.api.BillingClient.BillingResponse;
import com.android.billingclient.api.BillingClient.SkuType;
import java.util.List;
import org.json.JSONException;
import org.json.JSONObject;

/** Represents an in-app product's or subscription's listing details. */
public class SkuDetails {
  private final String mOriginalJson;
  private final JSONObject mParsedJson;

  public SkuDetails(String jsonSkuDetails) throws JSONException {
    mOriginalJson = jsonSkuDetails;
    mParsedJson = new JSONObject(mOriginalJson);
  }

  /** Returns the product Id. */
  public String getSku() {
    return mParsedJson.optString("productId");
  }

  /** Returns SKU type. */
  @SuppressWarnings("WrongConstant")
  @SkuType
  public String getType() {
    return mParsedJson.optString("type");
  }

  /**
   * Returns formatted price of the item, including its currency sign. The price does not include
   * tax.
   */
  public String getPrice() {
    return mParsedJson.optString("price");
  }

  /**
   * Returns price in micro-units, where 1,000,000 micro-units equal one unit of the currency.
   *
   * <p>For example, if price is "€7.99", price_amount_micros is "7990000". This value represents
   * the localized, rounded price for a particular currency.
   */
  public long getPriceAmountMicros() {
    return mParsedJson.optLong("price_amount_micros");
  }

  /**
   * Returns ISO 4217 currency code for price.
   *
   * <p>For example, if price is specified in British pounds sterling, price_currency_code is "GBP".
   */
  public String getPriceCurrencyCode() {
    return mParsedJson.optString("price_currency_code");
  }

  /** Returns the title of the product. */
  public String getTitle() {
    return mParsedJson.optString("title");
  }

  /** Returns the description of the product. */
  public String getDescription() {
    return mParsedJson.optString("description");
  }

  /**
   * Subscription period, specified in ISO 8601 format. For example, P1W equates to one week, P1M
   * equates to one month, P3M equates to three months, P6M equates to six months, and P1Y equates
   * to one year.
   *
   * <p>Note: Returned only for subscriptions.
   */
  public String getSubscriptionPeriod() {
    return mParsedJson.optString("subscriptionPeriod");
  }

  /**
   * Trial period configured in Google Play Console, specified in ISO 8601 format. For example, P7D
   * equates to seven days. To learn more about free trial eligibility, see In-app Subscriptions.
   *
   * <p>Note: Returned only for subscriptions which have a trial period configured.
   */
  public String getFreeTrialPeriod() {
    return mParsedJson.optString("freeTrialPeriod");
  }

  /**
   * Formatted introductory price of a subscription, including its currency sign, such as €3.99. The
   * price doesn't include tax.
   *
   * <p>Note: Returned only for subscriptions which have an introductory period configured.
   */
  public String getIntroductoryPrice() {
    return mParsedJson.optString("introductoryPrice");
  }

  /**
   * Introductory price in micro-units. The currency is the same as price_currency_code.
   *
   * <p>Note: Returned only for subscriptions which have an introductory period configured.
   */
  public String getIntroductoryPriceAmountMicros() {
    return mParsedJson.optString("introductoryPriceAmountMicros");
  }

  /**
   * The billing period of the introductory price, specified in ISO 8601 format.
   *
   * <p>Note: Returned only for subscriptions which have an introductory period configured.
   */
  public String getIntroductoryPricePeriod() {
    return mParsedJson.optString("introductoryPricePeriod");
  }

  /**
   * The number of subscription billing periods for which the user will be given the introductory
   * price, such as 3.
   *
   * <p>Note: Returned only for subscriptions which have an introductory period configured.
   */
  public String getIntroductoryPriceCycles() {
    return mParsedJson.optString("introductoryPriceCycles");
  }

  @Override
  public String toString() {
    return "SkuDetails: " + mOriginalJson;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }

    SkuDetails details = (SkuDetails) o;

    return TextUtils.equals(mOriginalJson, details.mOriginalJson);
  }

  @Override
  public int hashCode() {
    return mOriginalJson.hashCode();
  }

  /** Result list and code for querySkuDetailsAsync method */
  static class SkuDetailsResult {
    private List<SkuDetails> mSkuDetailsList;
    @BillingResponse private int mResponseCode;

    SkuDetailsResult(@BillingResponse int responseCode, List<SkuDetails> skuDetailsList) {
      this.mSkuDetailsList = skuDetailsList;
      this.mResponseCode = responseCode;
    }

    List<SkuDetails> getSkuDetailsList() {
      return mSkuDetailsList;
    }

    @BillingResponse
    int getResponseCode() {
      return mResponseCode;
    }
  }
}
