package com.android.billingclient.api;

import static com.android.billingclient.util.BillingHelper.INAPP_CONTINUATION_TOKEN;
import static com.android.billingclient.util.BillingHelper.RESPONSE_BUY_INTENT;
import static java.lang.annotation.RetentionPolicy.SOURCE;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.RemoteException;
import android.support.annotation.IntDef;
import android.support.annotation.NonNull;
import android.support.annotation.UiThread;
import android.support.annotation.VisibleForTesting;
import android.support.annotation.WorkerThread;
import android.text.TextUtils;
import com.android.billingclient.api.Purchase.PurchasesResult;
import com.android.billingclient.api.SkuDetails.SkuDetailsResult;
import com.android.billingclient.util.BillingHelper;
import com.android.vending.billing.IInAppBillingService;
import java.lang.annotation.Retention;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONException;

/**
 * Implementation of {@link BillingClient} for communication between the in-app billing library and
 * client's application code.
 */
class BillingClientImpl extends BillingClient {
  private static final String TAG = "BillingClient";

  /**
   * The maximum number of items than can be requested by a call to Billing service's
   * getSkuDetails() method
   */
  private static final int MAX_SKU_DETAILS_ITEMS_PER_REQUEST = 20;

  /** Possible client/billing service relationship states. */
  @IntDef({
    ClientState.DISCONNECTED,
    ClientState.CONNECTING,
    ClientState.CONNECTED,
    ClientState.CLOSED
  })
  @Retention(SOURCE)
  public @interface ClientState {
    /** This client was not yet connected to billing service or was already disconnected from it. */
    int DISCONNECTED = 0;
    /** This client is currently in process of connecting to billing service. */
    int CONNECTING = 1;
    /** This client is currently connected to billing service. */
    int CONNECTED = 2;
    /** This client was already closed and shouldn't be used again. */
    int CLOSED = 3;
  }

  private @ClientState int mClientState = ClientState.DISCONNECTED;

  /** A list of SKUs inside getSkuDetails request bundle. */
  private static final String GET_SKU_DETAILS_ITEM_LIST = "ITEM_ID_LIST";

  /** Field's key to hold VR related constant. */
  private static final String KEY_VR = "vr";

  /** Field's key to hold library version key constant. */
  private static final String LIBRARY_VERSION_KEY = "libraryVersion";

  /** Field's key value to hold current library version. */
  private static final String LIBRARY_VERSION = "1.0";

  /** Main thread handler to post results from Executor. */
  private final Handler mUiThreadHandler = new Handler();

  /**
   * Wrapper on top of PURCHASES_UPDATED broadcast receiver to return all purchases receipts to the
   * developer in one place for both app initiated and Play Store initated purhases.
   */
  private final BillingBroadcastManager mBroadcastManager;

  /** Context of the application that initialized this client. */
  private final Context mApplicationContext;

  /** Service binder */
  private IInAppBillingService mService;

  /** Connection to the service. */
  private ServiceConnection mServiceConnection;

  /** If subscriptions are is supported (for billing v3 and higher) or not. */
  private boolean mSubscriptionsSupported;

  /** If subscription update is supported (for billing v5 and higher) or not. */
  private boolean mSubscriptionUpdateSupported;

  /**
   * If purchaseHistory and buyIntentExtraParams are supported (for billing v6 and higher) or not.
   */
  private boolean mIABv6Supported;

  /**
   * Service that helps us to keep a pool of background threads suitable for current device specs.
   */
  private ExecutorService mExecutorService;

  /**
   * This receiver is triggered by local broadcast, once {@link ProxyBillingActivity} got the result
   * from Play Billing service in regards to current purchase process.
   */
  private final BroadcastReceiver onPurchaseFinishedReceiver =
      new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
          PurchasesUpdatedListener purchasesUpdatedListener = mBroadcastManager.getListener();
          if (purchasesUpdatedListener == null) {
            BillingHelper.logWarn(
                TAG, "PurchasesUpdatedListener is null - no way to return the response.");
            return;
          }
          // Receiving the result from local broadcast and triggering a callback on listener.
          @BillingResponse
          int responseCode =
              intent.getIntExtra(ProxyBillingActivity.RESPONSE_CODE, BillingResponse.ERROR);
          Bundle resultData = intent.getBundleExtra(ProxyBillingActivity.RESPONSE_BUNDLE);
          List<Purchase> purchases = BillingHelper.extractPurchases(resultData);
          purchasesUpdatedListener.onPurchasesUpdated(responseCode, purchases);
        }
      };

  @UiThread
  BillingClientImpl(@NonNull Context context, @NonNull PurchasesUpdatedListener listener) {
    mApplicationContext = context.getApplicationContext();
    mBroadcastManager = new BillingBroadcastManager(mApplicationContext, listener);
  }

  @Override
  public @BillingResponse int isFeatureSupported(@FeatureType String feature) {
    if (!isReady()) {
      return BillingResponse.SERVICE_DISCONNECTED;
    }

    switch (feature) {
      case FeatureType.SUBSCRIPTIONS:
        return mSubscriptionsSupported ? BillingResponse.OK : BillingResponse.FEATURE_NOT_SUPPORTED;

      case FeatureType.SUBSCRIPTIONS_UPDATE:
        return mSubscriptionUpdateSupported
            ? BillingResponse.OK
            : BillingResponse.FEATURE_NOT_SUPPORTED;

      case FeatureType.IN_APP_ITEMS_ON_VR:
        return isBillingSupportedOnVr(SkuType.INAPP);

      case FeatureType.SUBSCRIPTIONS_ON_VR:
        return isBillingSupportedOnVr(SkuType.SUBS);

      default:
        BillingHelper.logWarn(TAG, "Unsupported feature: " + feature);
        return BillingResponse.DEVELOPER_ERROR;
    }
  }

  @Override
  public boolean isReady() {
    return mClientState == ClientState.CONNECTED && mService != null && mServiceConnection != null;
  }

  @Override
  public void startConnection(@NonNull BillingClientStateListener listener) {
    if (isReady()) {
      BillingHelper.logVerbose(TAG, "Service connection is valid. No need to re-initialize.");
      listener.onBillingSetupFinished(BillingResponse.OK);
      return;
    }

    if (mClientState == ClientState.CONNECTING) {
      BillingHelper.logWarn(
          TAG, "Client is already in the process of connecting to billing service.");
      listener.onBillingSetupFinished(BillingResponse.DEVELOPER_ERROR);
      return;
    }

    if (mClientState == ClientState.CLOSED) {
      BillingHelper.logWarn(
          TAG, "Client was already closed and can't be reused. Please create another instance.");
      listener.onBillingSetupFinished(BillingResponse.DEVELOPER_ERROR);
      return;
    }

    // Switch current state to connecting to avoid race conditions
    mClientState = ClientState.CONNECTING;

    // Start listening for asynchronous purchase results via PURCHASES_UPDATED broadcasts
    mBroadcastManager.registerReceiver();

    // Subscribe to LocalBroadcastManager to get the synchronous purchase result from
    // ProxyBillingActivity
    IntentFilter purchaseIntent = new IntentFilter(ProxyBillingActivity.RESPONSE_INTENT_ACTION);
    LocalBroadcastManager.getInstance(mApplicationContext)
        .registerReceiver(onPurchaseFinishedReceiver, purchaseIntent);

    // Connection to billing service
    BillingHelper.logVerbose(TAG, "Starting in-app billing setup.");
    mServiceConnection = new BillingServiceConnection(listener);

    Intent serviceIntent = new Intent("com.android.vending.billing.InAppBillingService.BIND");
    serviceIntent.setPackage("com.android.vending");
    List<ResolveInfo> intentServices =
        mApplicationContext.getPackageManager().queryIntentServices(serviceIntent, 0);

    if (intentServices != null && !intentServices.isEmpty()) {
      // Get component info and create ComponentName
      ResolveInfo resolveInfo = intentServices.get(0);
      if (resolveInfo.serviceInfo != null) {
        String packageName = resolveInfo.serviceInfo.packageName;
        String className = resolveInfo.serviceInfo.name;
        if ("com.android.vending".equals(packageName) && className != null) {
          ComponentName component = new ComponentName(packageName, className);
          // Specify component explicitly and don't allow stripping or replacing the package name
          // to avoid exceptions inside 3rd party apps when Play Store was hacked:
          // "IllegalArgumentException: Service Intent must be explicit".
          // See: https://github.com/googlesamples/android-play-billing/issues/62 for more context.
          Intent explicitServiceIntent = new Intent(serviceIntent);
          explicitServiceIntent.setComponent(component);
          explicitServiceIntent.putExtra(LIBRARY_VERSION_KEY, LIBRARY_VERSION);
          boolean connectionResult =
              mApplicationContext.bindService(
                  explicitServiceIntent, mServiceConnection, Context.BIND_AUTO_CREATE);
          if (connectionResult) {
            // Service connected successfully, listener will be called from mServiceConnection
            BillingHelper.logVerbose(TAG, "Service was bonded successfully.");
            return;
          } else {
            // Service connection was blocked (e.g. this could happen in China), so we are closing
            // the connection and notifying the listener
            BillingHelper.logWarn(TAG, "Connection to Billing service is blocked.");
          }
        } else {
          // Play Store package name is not valid, ending connection
          BillingHelper.logWarn(TAG, "The device doesn't have valid Play Store.");
        }
      }
    }
    // No service available to handle that Intent or service connection was blocked
    mClientState = ClientState.DISCONNECTED;
    BillingHelper.logVerbose(TAG, "Billing service unavailable on device.");
    listener.onBillingSetupFinished(BillingResponse.BILLING_UNAVAILABLE);
  }

  @Override
  public void endConnection() {
    LocalBroadcastManager.getInstance(mApplicationContext)
        .unregisterReceiver(onPurchaseFinishedReceiver);
    mBroadcastManager.destroy();
    mClientState = ClientState.CLOSED;
    if (mServiceConnection != null) {
      BillingHelper.logVerbose(TAG, "Unbinding from service.");
      mApplicationContext.unbindService(mServiceConnection);
      mServiceConnection = null;
    }
    mService = null;
    if (mExecutorService != null) {
      mExecutorService.shutdownNow();
      mExecutorService = null;
    }
  }

  @Override
  public int launchBillingFlow(Activity activity, BillingFlowParams params) {
    if (!isReady()) {
      return BillingResponse.SERVICE_DISCONNECTED;
    }

    @SkuType String skuType = params.getSkuType();
    String newSku = params.getSku();
    String developerPayload = params.getDeveloperPayload();

    // Checking for mandatory params fields
    if (newSku == null) {
      BillingHelper.logWarn(TAG, "Please fix the input params. SKU can't be null.");
      return BillingResponse.DEVELOPER_ERROR;
    }

    if (skuType == null) {
      BillingHelper.logWarn(TAG, "Please fix the input params. SkuType can't be null.");
      return BillingResponse.DEVELOPER_ERROR;
    }

    if (params.getOldSkus() != null && params.getOldSkus().size() < 1) {
      BillingHelper.logWarn(TAG, "Please fix the input params. OldSkus size can't be 0.");
      return BillingResponse.DEVELOPER_ERROR;
    }

    // Checking for requested features support
    if (skuType.equals(SkuType.SUBS) && !mSubscriptionsSupported) {
      BillingHelper.logWarn(TAG, "Current client doesn't support subscriptions.");
      return BillingResponse.FEATURE_NOT_SUPPORTED;
    }

    boolean isSubscriptionUpdate = (params.getOldSkus() != null);

    if (isSubscriptionUpdate && !mSubscriptionUpdateSupported) {
      BillingHelper.logWarn(TAG, "Current client doesn't support subscriptions update.");
      return BillingResponse.FEATURE_NOT_SUPPORTED;
    }

    if (params.hasExtraParams() && !mIABv6Supported) {
      BillingHelper.logWarn(TAG, "Current client doesn't support extra params for buy intent.");
      return BillingResponse.FEATURE_NOT_SUPPORTED;
    }

    try {
      BillingHelper.logVerbose(
          TAG, "Constructing buy intent for " + newSku + ", " + "item type: " + skuType);

      Bundle buyIntentBundle;
      // If IAB v6 is supported, we always try to use buyIntentExtraParams and report the version
      if (mIABv6Supported) {
        Bundle extraParams = constructExtraParams(params);
        extraParams.putString(LIBRARY_VERSION_KEY, LIBRARY_VERSION);
        int apiVersion = (params.getVrPurchaseFlow()) ? 7 : 6;
        buyIntentBundle =
            mService.getBuyIntentExtraParams(
                apiVersion,
                mApplicationContext.getPackageName(),
                newSku,
                skuType,
                developerPayload,
                extraParams);
      } else if (isSubscriptionUpdate) {
        // For subscriptions update we are calling corresponding service method
        buyIntentBundle =
            mService.getBuyIntentToReplaceSkus(
                /* apiVersion */ 5,
                mApplicationContext.getPackageName(),
                params.getOldSkus(),
                newSku,
                SkuType.SUBS,
                developerPayload);
      } else {
        buyIntentBundle =
            mService.getBuyIntent(
                /* apiVersion */ 3,
                mApplicationContext.getPackageName(),
                newSku,
                skuType,
                developerPayload);
      }

      int responseCode = BillingHelper.getResponseCodeFromBundle(buyIntentBundle, TAG);
      if (responseCode != BillingResponse.OK) {
        BillingHelper.logWarn(TAG, "Unable to buy item, Error response code: " + responseCode);
        return responseCode;
      }
      // Launching an invisible activity that will handle the purchase result
      Intent intent = new Intent(activity, ProxyBillingActivity.class);
      intent.putExtra(RESPONSE_BUY_INTENT, buyIntentBundle.getParcelable(RESPONSE_BUY_INTENT));
      // We need an activity reference here to avoid using FLAG_ACTIVITY_NEW_TASK.
      // But we don't want to keep a reference to it inside the field to avoid memory leaks.
      // Plus all the other methods need just a Context reference, so could be used from the
      // Service or Application.
      activity.startActivity(intent);
    } catch (RemoteException e) {
      String msg =
          "RemoteException while launching launching replace subscriptions flow: "
              + "; for sku: "
              + newSku
              + "; try to reconnect";
      BillingHelper.logWarn(TAG, msg);
      return BillingResponse.SERVICE_DISCONNECTED;
    }

    return BillingResponse.OK;
  }

  @Override
  public PurchasesResult queryPurchases(@SkuType String skuType) {
    if (!isReady()) {
      return new PurchasesResult(BillingResponse.SERVICE_DISCONNECTED, /* purchasesList */ null);
    }

    // Checking for the mandatory argument
    if (TextUtils.isEmpty(skuType)) {
      BillingHelper.logWarn(TAG, "Please provide a valid SKU type.");
      return new PurchasesResult(BillingResponse.DEVELOPER_ERROR, /* purchasesList */ null);
    }

    return queryPurchasesInternal(skuType, false /* queryHistory */);
  }

  @Override
  public void querySkuDetailsAsync(
      SkuDetailsParams params, final SkuDetailsResponseListener listener) {
    if (!isReady()) {
      listener.onSkuDetailsResponse(
          BillingResponse.SERVICE_DISCONNECTED, /* skuDetailsList */ null);
    }

    final @SkuType String skuType = params.getSkuType();
    final List<String> skusList = params.getSkusList();

    // Checking for mandatory params fields
    if (TextUtils.isEmpty(skuType)) {
      BillingHelper.logWarn(TAG, "Please fix the input params. SKU type can't be empty.");
      listener.onSkuDetailsResponse(BillingResponse.DEVELOPER_ERROR, /* skuDetailsList */ null);
      return;
    }

    if (skusList == null) {
      BillingHelper.logWarn(TAG, "Please fix the input params. The list of SKUs can't be empty.");
      listener.onSkuDetailsResponse(BillingResponse.DEVELOPER_ERROR, /* skuDetailsList */ null);
      return;
    }

    executeAsync(
        new Runnable() {
          @Override
          public void run() {
            final SkuDetailsResult result = querySkuDetailsInternal(skuType, skusList);
            // Post the result to main thread
            postToUiThread(
                new Runnable() {
                  @Override
                  public void run() {
                    listener.onSkuDetailsResponse(
                        result.getResponseCode(), result.getSkuDetailsList());
                  }
                });
          }
        });
  }

  @Override
  public void consumeAsync(final String purchaseToken, final ConsumeResponseListener listener) {
    if (!isReady()) {
      listener.onConsumeResponse(BillingResponse.SERVICE_DISCONNECTED, /* purchaseToken */ null);
    }

    // Checking for the mandatory argument
    if (TextUtils.isEmpty(purchaseToken)) {
      BillingHelper.logWarn(
          TAG, "Please provide a valid purchase token got from queryPurchases result.");
      listener.onConsumeResponse(BillingResponse.DEVELOPER_ERROR, purchaseToken);
      return;
    }

    executeAsync(
        new Runnable() {
          @Override
          public void run() {
            consumeInternal(purchaseToken, listener);
          }
        });
  }

  @Override
  public void queryPurchaseHistoryAsync(
      final @SkuType String skuType, final PurchaseHistoryResponseListener listener) {
    if (!isReady()) {
      listener.onPurchaseHistoryResponse(
          BillingResponse.SERVICE_DISCONNECTED, /* purchasesList */ null);
    }

    executeAsync(
        new Runnable() {
          @Override
          public void run() {
            final PurchasesResult result = queryPurchasesInternal(skuType, /* queryHistory */ true);

            // Post the result to main thread
            postToUiThread(
                new Runnable() {
                  @Override
                  public void run() {
                    listener.onPurchaseHistoryResponse(
                        result.getResponseCode(), result.getPurchasesList());
                  }
                });
          }
        });
  }

  private Bundle constructExtraParams(BillingFlowParams params) {
    Bundle extraParams = new Bundle();

    if (!params.getReplaceSkusProration()) {
      extraParams.putBoolean("replaceSkusProration", false);
    }
    if (params.getAccountId() != null) {
      extraParams.putString("accountId", params.getAccountId());
    }
    if (params.getVrPurchaseFlow()) {
      extraParams.putBoolean(KEY_VR, true);
    }
    if (params.getOldSkus() != null) {
      extraParams.putStringArrayList("skusToReplace", params.getOldSkus());
    }

    return extraParams;
  }

  private void executeAsync(Runnable runnable) {
    if (mExecutorService == null) {
      mExecutorService = Executors.newFixedThreadPool(BillingHelper.NUMBER_OF_CORES);
    }

    mExecutorService.submit(runnable);
  }

  /** Checks if billing on VR is supported for corresponding billing type. */
  private int isBillingSupportedOnVr(@SkuType String skuType) {
    try {
      int supportedResult =
          mService.isBillingSupportedExtraParams(
              7 /* apiVersion */,
              mApplicationContext.getPackageName(),
              skuType,
              generateVrBundle());
      return (supportedResult == BillingResponse.OK)
          ? BillingResponse.OK
          : BillingResponse.FEATURE_NOT_SUPPORTED;
    } catch (RemoteException e) {
      BillingHelper.logWarn(
          TAG, "RemoteException while checking if billing is supported; " + "try to reconnect");
      return BillingResponse.SERVICE_DISCONNECTED;
    }
  }

  /**
   * Generates a Bundle to indicate that we are request a method for VR experience within
   * extraParams
   */
  private Bundle generateVrBundle() {
    Bundle result = new Bundle();
    result.putBoolean(KEY_VR, true);
    return result;
  }

  @VisibleForTesting
  SkuDetailsResult querySkuDetailsInternal(@SkuType String skuType, List<String> skuList) {
    List<SkuDetails> resultList = new ArrayList<>();

    // Split the sku list into packs of no more than MAX_SKU_DETAILS_ITEMS_PER_REQUEST elements
    int startIndex = 0, listSize = skuList.size();
    while (startIndex < listSize) {
      // Prepare a network request up to a maximum amount of supported elements
      int endIndex = startIndex + MAX_SKU_DETAILS_ITEMS_PER_REQUEST;
      if (endIndex > listSize) {
        endIndex = listSize;
      }
      ArrayList<String> curSkuList = new ArrayList<>(skuList.subList(startIndex, endIndex));
      Bundle querySkus = new Bundle();
      querySkus.putStringArrayList(GET_SKU_DETAILS_ITEM_LIST, curSkuList);
      querySkus.putString(LIBRARY_VERSION_KEY, LIBRARY_VERSION);
      Bundle skuDetails;
      try {
        skuDetails =
            mService.getSkuDetails(3, mApplicationContext.getPackageName(), skuType, querySkus);
      } catch (RemoteException e) {
        String msg = "querySkuDetailsAsync got a remote exception (try to reconnect): " + e;
        BillingHelper.logWarn(TAG, msg);
        return new SkuDetailsResult(
            BillingResponse.SERVICE_DISCONNECTED, /* skuDetailsList */ null);
      }

      if (skuDetails == null) {
        BillingHelper.logWarn(TAG, "querySkuDetailsAsync got null sku details list");
        return new SkuDetailsResult(BillingResponse.ITEM_UNAVAILABLE, /* skuDetailsList */ null);
      }

      if (!skuDetails.containsKey(BillingHelper.RESPONSE_GET_SKU_DETAILS_LIST)) {
        @BillingResponse
        int responseCode = BillingHelper.getResponseCodeFromBundle(skuDetails, TAG);

        if (responseCode != BillingResponse.OK) {
          BillingHelper.logWarn(TAG, "getSkuDetails() failed. Response code: " + responseCode);
          return new SkuDetailsResult(responseCode, resultList);
        } else {
          BillingHelper.logWarn(
              TAG,
              "getSkuDetails() returned a bundle with neither" + " an error nor a detail list.");
          return new SkuDetailsResult(BillingResponse.ERROR, resultList);
        }
      }

      ArrayList<String> skuDetailsJsonList =
          skuDetails.getStringArrayList(BillingHelper.RESPONSE_GET_SKU_DETAILS_LIST);

      if (skuDetailsJsonList == null) {
        BillingHelper.logWarn(TAG, "querySkuDetailsAsync got null response list");
        return new SkuDetailsResult(BillingResponse.ITEM_UNAVAILABLE, /* skuDetailsList */ null);
      }

      for (int i = 0; i < skuDetailsJsonList.size(); ++i) {
        String thisResponse = skuDetailsJsonList.get(i);
        SkuDetails currentSkuDetails;
        try {
          currentSkuDetails = new SkuDetails(thisResponse);
        } catch (JSONException e) {
          BillingHelper.logWarn(TAG, "Got a JSON exception trying to decode SkuDetails");
          return new SkuDetailsResult(BillingResponse.ERROR, /* skuDetailsList */ null);
        }
        BillingHelper.logVerbose(TAG, "Got sku details: " + currentSkuDetails);
        resultList.add(currentSkuDetails);
      }

      // Switching start index to the end of just received pack
      startIndex += MAX_SKU_DETAILS_ITEMS_PER_REQUEST;
    }

    return new SkuDetailsResult(BillingResponse.OK, resultList);
  }

  /**
   * Queries purchases or purchases history and combines all the multi-page results into one list
   */
  private PurchasesResult queryPurchasesInternal(@SkuType String skuType, boolean queryHistory) {
    BillingHelper.logVerbose(
        TAG, "Querying owned items, item type: " + skuType + "; " + "history: " + queryHistory);

    String continueToken = null;
    List<Purchase> resultList = new ArrayList<>();

    do {
      Bundle ownedItems;
      try {
        if (queryHistory) {
          // If current client doesn't support IABv6, then there is no such method yet
          if (!mIABv6Supported) {
            BillingHelper.logWarn(TAG, "getPurchaseHistory is not supported on current device");
            return new PurchasesResult(
                BillingResponse.FEATURE_NOT_SUPPORTED, /* purchasesList */ null);
          }
          ownedItems =
              mService.getPurchaseHistory(
                  /* apiVersion */ 6,
                  mApplicationContext.getPackageName(),
                  skuType,
                  continueToken,
                  /* extraParams */ null);
        } else {
          ownedItems =
              mService.getPurchases(
                  3 /* apiVersion */, mApplicationContext.getPackageName(), skuType, continueToken);
        }
      } catch (RemoteException e) {
        BillingHelper.logWarn(
            TAG, "Got exception trying to get purchases: " + e + "; try to reconnect");
        return new PurchasesResult(BillingResponse.SERVICE_DISCONNECTED, /* purchasesList */ null);
      }

      if (ownedItems == null) {
        BillingHelper.logWarn(TAG, "queryPurchases got null owned items list");
        return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
      }

      @BillingResponse int responseCode = BillingHelper.getResponseCodeFromBundle(ownedItems, TAG);

      if (responseCode != BillingResponse.OK) {
        BillingHelper.logWarn(TAG, "getPurchases() failed. Response code: " + responseCode);
        return new PurchasesResult(responseCode, /* purchasesList */ null);
      }

      if (!ownedItems.containsKey(BillingHelper.RESPONSE_INAPP_ITEM_LIST)
          || !ownedItems.containsKey(BillingHelper.RESPONSE_INAPP_PURCHASE_DATA_LIST)
          || !ownedItems.containsKey(BillingHelper.RESPONSE_INAPP_SIGNATURE_LIST)) {
        BillingHelper.logWarn(
            TAG, "Bundle returned from getPurchases() doesn't contain required fields.");
        return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
      }

      ArrayList<String> ownedSkus =
          ownedItems.getStringArrayList(BillingHelper.RESPONSE_INAPP_ITEM_LIST);
      ArrayList<String> purchaseDataList =
          ownedItems.getStringArrayList(BillingHelper.RESPONSE_INAPP_PURCHASE_DATA_LIST);
      ArrayList<String> signatureList =
          ownedItems.getStringArrayList(BillingHelper.RESPONSE_INAPP_SIGNATURE_LIST);

      if (ownedSkus == null) {
        BillingHelper.logWarn(TAG, "Bundle returned from getPurchases() contains null SKUs list.");
        return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
      }

      if (purchaseDataList == null) {
        BillingHelper.logWarn(
            TAG, "Bundle returned from getPurchases() contains null purchases list.");
        return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
      }

      if (signatureList == null) {
        BillingHelper.logWarn(
            TAG, "Bundle returned from getPurchases() contains null signatures list.");
        return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
      }

      for (int i = 0; i < purchaseDataList.size(); ++i) {
        String purchaseData = purchaseDataList.get(i);
        String signature = signatureList.get(i);
        String sku = ownedSkus.get(i);

        BillingHelper.logVerbose(TAG, "Sku is owned: " + sku);
        Purchase purchase;
        try {
          purchase = new Purchase(purchaseData, signature);
        } catch (JSONException e) {
          BillingHelper.logWarn(TAG, "Got an exception trying to decode the purchase: " + e);
          return new PurchasesResult(BillingResponse.ERROR, /* purchasesList */ null);
        }

        if (TextUtils.isEmpty(purchase.getPurchaseToken())) {
          BillingHelper.logWarn(TAG, "BUG: empty/null token!");
        }

        resultList.add(purchase);
      }

      continueToken = ownedItems.getString(INAPP_CONTINUATION_TOKEN);
      BillingHelper.logVerbose(TAG, "Continuation token: " + continueToken);
    } while (!TextUtils.isEmpty(continueToken));

    return new PurchasesResult(BillingResponse.OK, resultList);
  }

  /** Execute the runnable on the UI/Main Thread */
  private void postToUiThread(Runnable runnable) {
    mUiThreadHandler.post(runnable);
  }

  /** Consume the purchase and execute listener's callback on the Ui/Main thread */
  @WorkerThread
  private void consumeInternal(final String purchaseToken, final ConsumeResponseListener listener) {
    try {
      BillingHelper.logVerbose(TAG, "Consuming purchase with token: " + purchaseToken);
      final @BillingResponse int responseCode =
          mService.consumePurchase(
              3 /* apiVersion */, mApplicationContext.getPackageName(), purchaseToken);

      if (responseCode == BillingResponse.OK) {
        BillingHelper.logVerbose(TAG, "Successfully consumed purchase.");
        if (listener != null) {
          postToUiThread(
              new Runnable() {
                @Override
                public void run() {
                  listener.onConsumeResponse(responseCode, purchaseToken);
                }
              });
        }
      } else {
        BillingHelper.logWarn(
            TAG, "Error consuming purchase with token. Response code: " + responseCode);

        postToUiThread(
            new Runnable() {
              @Override
              public void run() {
                BillingHelper.logWarn(TAG, "Error consuming purchase.");
                listener.onConsumeResponse(responseCode, purchaseToken);
              }
            });
      }
    } catch (final RemoteException e) {
      postToUiThread(
          new Runnable() {
            @Override
            public void run() {
              BillingHelper.logWarn(TAG, "Error consuming purchase; ex: " + e);
              listener.onConsumeResponse(BillingResponse.SERVICE_DISCONNECTED, purchaseToken);
            }
          });
    }
  }

  /** Connect with Billing service and notify listener about important states. */
  private final class BillingServiceConnection implements ServiceConnection {
    private final BillingClientStateListener mListener;

    private BillingServiceConnection(@NonNull BillingClientStateListener listener) {
      if (listener == null) {
        throw new RuntimeException("Please specify a listener to know when init is done.");
      }
      mListener = listener;
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
      BillingHelper.logWarn(TAG, "Billing service disconnected.");
      mService = null;
      mClientState = ClientState.DISCONNECTED;
      mListener.onBillingServiceDisconnected();
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
      BillingHelper.logVerbose(TAG, "Billing service connected.");

      mService = IInAppBillingService.Stub.asInterface(service);
      String packageName = mApplicationContext.getPackageName();
      mSubscriptionsSupported = false;
      mSubscriptionUpdateSupported = false;
      mIABv6Supported = false;
      // The code below tries to figure out, which IAB API version and features are supported by
      // current client (Play Store app on this device).
      // First, it checks for IABv6 with subscriptions to avoid extra queries for most of the
      // clients.
      // Second, it checks if IABv6 is supported for in-app only items.
      // Third, it checks for IABv5 for subscription only (since only getBuyIntentToReplaceSku was
      // added during that release).
      // And finally it checks for IABv3 for both subscriptions and inapp items.
      try {
        // Check for in-app billing API v6 support with subscriptions. This is needed for
        // getPurchaseHistory and getBuyIntentExtraParams methods.
        @BillingResponse
        int response = mService.isBillingSupported(/* apiVersion */ 6, packageName, SkuType.SUBS);

        if (response == BillingResponse.OK) {
          BillingHelper.logVerbose(TAG, "In-app billing API version 6 with subs is supported.");
          mIABv6Supported = true;
          mSubscriptionsSupported = true;
          mSubscriptionUpdateSupported = true;
        } else {
          // Check for in-app billing API v6 support without subcriptions. This is needed for
          // getPurchaseHistory and getBuyIntentExtraParams methods.
          // noinspection WrongConstant
          response = mService.isBillingSupported(/* apiVersion */ 6, packageName, SkuType.INAPP);

          if (response == BillingResponse.OK) {
            BillingHelper.logVerbose(TAG, "In-app billing API without subs version 6 supported.");
            mIABv6Supported = true;
          }

          // Check for in-app billing API v5 support. This is needed for
          // getBuyIntentToReplaceSku which allows for subscription update
          // noinspection WrongConstant
          response = mService.isBillingSupported(/* apiVersion */ 5, packageName, SkuType.SUBS);

          if (response == BillingResponse.OK) {
            BillingHelper.logVerbose(TAG, "In-app billing API version 5 supported.");
            mSubscriptionUpdateSupported = true;
            mSubscriptionsSupported = true;
          } else {
            // Check for in-app billing API v3 support with subscriptions
            // noinspection WrongConstant
            response = mService.isBillingSupported(/* apiVersion */ 3, packageName, SkuType.SUBS);

            if (response == BillingResponse.OK) {
              BillingHelper.logVerbose(
                  TAG, "In-app billing API version 3 with subscriptions is supported.");
              mSubscriptionsSupported = true;
            } else if (mIABv6Supported) {
              // If IABv6 without subscriptions was already checked, then we return successful
              // result even though subscriptions are not supported even for IABv3. This is a valid
              // case for our Android Wear client, for example.
              response = BillingResponse.OK;
            } else {
              // Check for at least in-app billing API v3 support with in-app items only
              // noinspection WrongConstant
              response =
                  mService.isBillingSupported(/* apiVersion */ 3, packageName, SkuType.INAPP);

              if (response == BillingResponse.OK) {
                BillingHelper.logVerbose(
                    TAG, "In-app billing API version 3 with in-app items is supported.");
              } else {
                BillingHelper.logWarn(
                    TAG, "Even billing API version 3 is not supported on this device.");
              }
            }
          }
        }

        if (response == BillingResponse.OK) {
          mClientState = ClientState.CONNECTED;
        } else {
          mClientState = ClientState.DISCONNECTED;
          mService = null;
        }
        mListener.onBillingSetupFinished(response);
      } catch (final RemoteException e) {
        BillingHelper.logWarn(TAG, "RemoteException while setting up in-app billing" + e);
        mClientState = ClientState.DISCONNECTED;
        mService = null;
        mListener.onBillingSetupFinished(BillingResponse.SERVICE_DISCONNECTED);
      }
    }
  }
}
