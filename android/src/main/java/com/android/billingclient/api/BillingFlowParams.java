package com.android.billingclient.api;

import static com.android.billingclient.api.BillingClient.SkuType;

import java.util.ArrayList;

/** Parameters to initiate a purchase flow. (See {@link BillingClient#launchBillingFlow}). */
public class BillingFlowParams {

  private String mSku;
  @SkuType private String mSkuType;
  private ArrayList<String> mOldSkus;
  private boolean mNotReplaceSkusProration;
  private String mAccountId;
  private boolean mVrPurchaseFlow;
  private String developerPayload;

  /**
   * Returns the SKU that is being purchased or upgraded/downgraded to as published in the Google
   * Developer console.
   */
  public String getSku() {
    return mSku;
  }

  /** Returns the billing type {@link SkuType} of the item being purchased. */
  @SkuType
  public String getSkuType() {
    return mSkuType;
  }

  /** Returns the SKU(s) that the user is upgrading or downgrading from. */
  public ArrayList<String> getOldSkus() {
    return mOldSkus;
  }

  /**
   * Returns whether the user should be credited for any unused subscription time on the SKUs they
   * are upgrading or downgrading.
   */
  public boolean getReplaceSkusProration() {
    return !mNotReplaceSkusProration;
  }

  /** Returns an optional obfuscated string that is uniquely associated with the user's account. */
  public String getAccountId() {
    return mAccountId;
  }

  /** Returns an optional flag indicating whether you wish to launch a VR purchase flow. */
  public boolean getVrPurchaseFlow() {
    return mVrPurchaseFlow;
  }

  /** Returns an optional developer payload. */
  public String getDeveloperPayload() {
    return developerPayload;
  }

  /** Returns whether it has an optional params for a custom purchase flow. */
  public boolean hasExtraParams() {
    return mNotReplaceSkusProration || mAccountId != null || mVrPurchaseFlow;
  }

  /** Constructs a new {@link Builder} instance. */
  public static Builder newBuilder() {
    return new Builder();
  }

  /** Helps to construct {@link BillingFlowParams} that are used to initiate a purchase flow. */
  public static class Builder {
    private BillingFlowParams mParams = new BillingFlowParams();

    private Builder() {}

    /**
     * Specify the SKU that is being purchased or upgraded/downgraded to as published in the Google
     * Developer console.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To buy in-app item
     *   <li>To create a new subscription
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setSku(String sku) {
      mParams.mSku = sku;
      return this;
    }

    /**
     * Specify the billing type {@link SkuType} of the item being purchased.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To buy in-app item
     *   <li>To create a new subscription
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setType(@SkuType String type) {
      mParams.mSkuType = type;
      return this;
    }

    /**
     * Specify the SKU(s) that the user is upgrading or downgrading from.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setOldSkus(ArrayList<String> oldSkus) {
      mParams.mOldSkus = oldSkus;
      return this;
    }

    /**
     * Add the SKU that the user is upgrading or downgrading from.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder addOldSku(String oldSku) {
      if (mParams.mOldSkus == null) {
        mParams.mOldSkus = new ArrayList<>();
      }
      mParams.mOldSkus.add(oldSku);
      return this;
    }

    /**
     * Specify an optional flag indicating whether the user should be credited for any unused
     * subscription time on the SKUs they are upgrading or downgrading.
     *
     * <p>If you set this field to false, the user does not receive credit for any unused
     * subscription time and the recurrence date does not change. Otherwise, Google Play swaps out
     * the old SKUs and credits the user with the unused value of their subscription time on a
     * pro-rated basis. Google Play applies this credit to the new subscription, and does not begin
     * billing the user for the new subscription until after the credit is used up.
     *
     * <p>Optional:
     *
     * <ul>
     *   <li>To buy in-app item
     *   <li>To create a new subscription
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setReplaceSkusProration(boolean bReplaceSkusProration) {
      mParams.mNotReplaceSkusProration = !bReplaceSkusProration;
      return this;
    }

    /**
     * Specify an optional obfuscated string that is uniquely associated with the user's account in
     * your app.
     *
     * <p>If you pass this value, Google Play can use it to detect irregular activity, such as many
     * devices making purchases on the same account in a short period of time. Do not use the
     * developer ID or the user's Google ID for this field. In addition, this field should not
     * contain the user's ID in cleartext. We recommend that you use a one-way hash to generate a
     * string from the user's ID and store the hashed string in this field.
     *
     * <p>Optional:
     *
     * <ul>
     *   <li>To buy in-app item
     *   <li>To create a new subscription
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setAccountId(String accountId) {
      mParams.mAccountId = accountId;
      return this;
    }

    /**
     * Specify an optional flag indicating whether you wish to launch a VR purchase flow.
     *
     * <p>Optional:
     *
     * <ul>
     *   <li>To buy in-app item
     *   <li>To create a new subscription
     *   <li>To replace an old subscription
     * </ul>
     */
    public Builder setVrPurchaseFlow(boolean isVrPurchaseFlow) {
      mParams.mVrPurchaseFlow = isVrPurchaseFlow;
      return this;
    }

    /**
     * Specify an optional developer payload field
     */
    public Builder setDeveloperPayload(String developerPayload) {
      mParams.developerPayload = developerPayload;
      return this;
    }

    /** Returns {@link BillingFlowParams} reference to initiate a purchase flow. */
    public BillingFlowParams build() {
      return mParams;
    }
  }
}
