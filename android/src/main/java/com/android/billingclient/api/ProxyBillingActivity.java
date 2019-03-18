package com.android.billingclient.api;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import com.android.billingclient.api.BillingClient.BillingResponse;
import com.android.billingclient.util.BillingHelper;

import static com.android.billingclient.util.BillingHelper.RESPONSE_BUY_INTENT;

/**
 * An invisible activity that handles the request from {@link BillingClient#launchBillingFlow} event
 * and delivers parsed result to the {@link BillingClient} via {@link LocalBroadcastManager}.
 */
public class ProxyBillingActivity extends Activity {
  static final String RESPONSE_INTENT_ACTION = "proxy_activity_response_intent_action";
  static final String RESPONSE_CODE = "response_code_key";
  static final String RESPONSE_BUNDLE = "response_bundle_key";

  private static final String TAG = "ProxyBillingActivity";
  private static final int REQUEST_CODE = 100;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    BillingHelper.logVerbose(TAG, "Launching Play Store billing flow");
    PendingIntent pendingIntent = getIntent().getParcelableExtra(RESPONSE_BUY_INTENT);

    try {
      startIntentSenderForResult(
          pendingIntent.getIntentSender(), REQUEST_CODE, new Intent(), 0, 0, 0);
    } catch (Throwable e) {
      BillingHelper.logWarn(TAG, "Got exception while trying to start a purchase flow: " + e);
      broadcastResult(BillingResponse.ERROR, null);
      finish();
    }
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);

    if (requestCode == REQUEST_CODE) {
      int responseCode = BillingHelper.getResponseCodeFromIntent(data, TAG);
      if (resultCode != RESULT_OK || responseCode != BillingResponse.OK) {
        BillingHelper.logWarn(
            TAG,
            "Got purchases updated result with resultCode "
                + resultCode
                + " and billing's responseCode: "
                + responseCode);
      }
      broadcastResult(responseCode, data == null ? null : data.getExtras());
    } else {
      BillingHelper.logWarn(
          TAG, "Got onActivityResult with wrong requestCode: " + requestCode + "; skipping...");
    }
    // Need to finish this invisible activity once we sent back the result
    finish();
  }

  private void broadcastResult(int responseCode, Bundle resultBundle) {
    Intent intent = new Intent(RESPONSE_INTENT_ACTION);
    intent.putExtra(RESPONSE_CODE, responseCode);
    intent.putExtra(RESPONSE_BUNDLE, resultBundle);
    LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
  }
}
