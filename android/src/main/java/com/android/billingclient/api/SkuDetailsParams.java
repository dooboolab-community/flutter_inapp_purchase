package com.android.billingclient.api;

import com.android.billingclient.api.BillingClient.SkuType;
import java.util.List;

/**
 * Parameters to initiate a query for SKU details. (See {@link BillingClient#querySkuDetailsAsync}
 */
public class SkuDetailsParams {
  private @SkuType String mSkuType;
  private List<String> mSkusList;

  public @SkuType String getSkuType() {
    return mSkuType;
  }

  public List<String> getSkusList() {
    return mSkusList;
  }

  /** Constructs a new {@link Builder} instance. */
  public static Builder newBuilder() {
    return new Builder();
  }

  /** Helps to construct {@link SkuDetailsParams} that are used to query for SKU details. */
  public static class Builder {
    private SkuDetailsParams mParams = new SkuDetailsParams();

    private Builder() {}

    /**
     * Specify the SKUs that are queried for as published in the Google Developer console.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To query for SKU details
     * </ul>
     */
    public Builder setSkusList(List<String> skusList) {
      mParams.mSkusList = skusList;
      return this;
    }

    /**
     * Specify the type {@link SkuType} of SKUs we are querying for.
     *
     * <p>Mandatory:
     *
     * <ul>
     *   <li>To query for SKU details
     * </ul>
     */
    public Builder setType(@SkuType String type) {
      mParams.mSkuType = type;
      return this;
    }

    /** Returns {@link SkuDetailsParams} reference to initiate a purchase flow. */
    public SkuDetailsParams build() {
      return mParams;
    }
  }
}
