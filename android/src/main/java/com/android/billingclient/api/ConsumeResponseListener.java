package com.android.billingclient.api;

import com.android.billingclient.api.BillingClient.BillingResponse;

/** Callback that notifies when a consumption operation finishes. */
public interface ConsumeResponseListener {
  /**
   * Called to notify that a consume operation has finished.
   *
   * @param responseCode The response code from {@link BillingResponse} set to report the result of
   *     consume operation.
   * @param purchaseToken The purchase token that was (or was to be) consumed.
   */
  void onConsumeResponse(@BillingResponse int responseCode, String purchaseToken);
}
