package com.android.billingclient.api;

import com.android.billingclient.api.BillingClient.BillingResponse;

/**
 * Callback for setup process. This listener's {@link #onBillingSetupFinished} method is called when
 * the setup process is complete.
 */
public interface BillingClientStateListener {
  /**
   * Called to notify that setup is complete.
   *
   * @param responseCode The response code from {@link BillingResponse} which returns the status of
   *     the setup process.
   */
  void onBillingSetupFinished(@BillingResponse int responseCode);

  /**
   * Called to notify that connection to billing service was lost
   *
   * <p>Note: This does not remove billing service connection itself - this binding to the service
   * will remain active, and you will receive a call to {@link #onBillingSetupFinished} when billing
   * service is next running and setup is complete.
   */
  void onBillingServiceDisconnected();
}
