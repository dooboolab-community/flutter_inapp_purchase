package com.android.billingclient.api;

import com.android.billingclient.api.BillingClient.BillingResponse;
import java.util.List;

/** Listener to a result of SKU details query */
public interface SkuDetailsResponseListener {
  /**
   * Called to notify that a fetch SKU details operation has finished.
   *
   * @param responseCode Response code of the update.
   * @param skuDetailsList List of SKU details.
   */
  void onSkuDetailsResponse(@BillingResponse int responseCode, List<SkuDetails> skuDetailsList);
}
