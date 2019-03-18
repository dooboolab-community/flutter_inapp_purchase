package com.android.billingclient.api;

import android.support.annotation.Nullable;
import com.android.billingclient.api.BillingClient.BillingResponse;
import java.util.List;

/**
 * Listener interface for purchase updates which happen when, for example, the user buys something
 * within the app or by initiating a purchase from Google Play Store.
 */
public interface PurchasesUpdatedListener {
  /**
   * Implement this method to get notifications for purchases updates. Both purchases initiated by
   * your app and the ones initiated by Play Store will be reported here.
   *
   * @param responseCode Response code of the update.
   * @param purchases List of updated purchases if present.
   */
  void onPurchasesUpdated(@BillingResponse int responseCode, @Nullable List<Purchase> purchases);
}
