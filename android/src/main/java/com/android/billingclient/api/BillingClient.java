package com.android.billingclient.api;

import static java.lang.annotation.RetentionPolicy.SOURCE;

import android.app.Activity;
import android.content.Context;
import android.support.annotation.IntDef;
import android.support.annotation.NonNull;
import android.support.annotation.StringDef;
import android.support.annotation.UiThread;
import com.android.billingclient.api.Purchase.PurchasesResult;
import java.lang.annotation.Retention;

/**
 * Main interface for communication between the library and user application code.
 *
 * <p>It provides convenience methods for in-app billing. You can create one instance of this class
 * for your application and use it to process in-app billing operations. It provides synchronous
 * (blocking) and asynchronous (non-blocking) methods for many common in-app billing operations.
 *
 * <p>All methods are supposed to be called from the Ui thread and all the asynchronous callbacks
 * will be returned on the Ui thread as well.
 *
 * <p>After instantiating, you must perform setup in order to start using the object. To perform
 * setup, call the {@link #startConnection} method and provide a listener; that listener will be
 * notified when setup is complete, after which (and not before) you may start calling other
 * methods. After setup is complete, you will typically want to request an inventory of owned items
 * and subscriptions. See {@link #queryPurchases} and {@link #querySkuDetailsAsync}.
 *
 * <p>When you are done with this object, don't forget to call {@link #endConnection()} to ensure
 * proper cleanup. This object holds a binding to the in-app billing service and the manager to
 * handle broadcast events, which will leak unless you dispose it correctly. If you created the
 * object inside the {@link Activity#onCreate} method, then the recommended place to dispose is the
 * the {@link Activity#onDestroy} method.
 *
 * <p>To get library logs inside Android logcat, set corresponding logging level.
 * E.g.: <code>adb shell setprop log.tag.BillingClient VERBOSE</code>
 */
public abstract class BillingClient {
  /** Supported SKU types. */
  @StringDef({SkuType.INAPP, SkuType.SUBS})
  @Retention(SOURCE)
  public @interface SkuType {
    /** A type of SKU for in-app products. */
    String INAPP = "inapp";
    /** A type of SKU for subscriptions. */
    String SUBS = "subs";
  }

  /** Features/capabilities supported by {@link #isFeatureSupported(String)}. */
  @StringDef({
    FeatureType.SUBSCRIPTIONS,
    FeatureType.SUBSCRIPTIONS_UPDATE,
    FeatureType.IN_APP_ITEMS_ON_VR,
    FeatureType.SUBSCRIPTIONS_ON_VR
  })
  @Retention(SOURCE)
  public @interface FeatureType {
    /** Purchase/query for subscriptions. */
    String SUBSCRIPTIONS = "subscriptions";
    /** Subscriptions update/replace. */
    String SUBSCRIPTIONS_UPDATE = "subscriptionsUpdate";
    /** Purchase/query for in-app items on VR. */
    String IN_APP_ITEMS_ON_VR = "inAppItemsOnVr";
    /** Purchase/query for subscriptions on VR. */
    String SUBSCRIPTIONS_ON_VR = "subscriptionsOnVr";
  }

  /** Possible response codes. */
  @IntDef({
    BillingResponse.FEATURE_NOT_SUPPORTED,
    BillingResponse.SERVICE_DISCONNECTED,
    BillingResponse.OK,
    BillingResponse.USER_CANCELED,
    BillingResponse.SERVICE_UNAVAILABLE,
    BillingResponse.BILLING_UNAVAILABLE,
    BillingResponse.ITEM_UNAVAILABLE,
    BillingResponse.DEVELOPER_ERROR,
    BillingResponse.ERROR,
    BillingResponse.ITEM_ALREADY_OWNED,
    BillingResponse.ITEM_NOT_OWNED
  })
  @Retention(SOURCE)
  public @interface BillingResponse {
    /** Requested feature is not supported by Play Store on the current device. */
    int FEATURE_NOT_SUPPORTED = -2;
    /**
     * Play Store service is not connected now - potentially transient state.
     *
     * <p>E.g. Play Store could have been updated in the background while your app was still
     * running. So feel free to introduce your retry policy for such use case. It should lead to a
     * call to {@link #startConnection} right after or in some time after you received this code.
     */
    int SERVICE_DISCONNECTED = -1;
    /** Success */
    int OK = 0;
    /** User pressed back or canceled a dialog */
    int USER_CANCELED = 1;
    /** Network connection is down */
    int SERVICE_UNAVAILABLE = 2;
    /** Billing API version is not supported for the type requested */
    int BILLING_UNAVAILABLE = 3;
    /** Requested product is not available for purchase */
    int ITEM_UNAVAILABLE = 4;
    /**
     * Invalid arguments provided to the API. This error can also indicate that the application was
     * not correctly signed or properly set up for In-app Billing in Google Play, or does not have
     * the necessary permissions in its manifest
     */
    int DEVELOPER_ERROR = 5;
    /** Fatal error during the API action */
    int ERROR = 6;
    /** Failure to purchase since item is already owned */
    int ITEM_ALREADY_OWNED = 7;
    /** Failure to consume since item is not owned */
    int ITEM_NOT_OWNED = 8;
  }

  /** Builder to configure and create a BillingClient instance. */
  public static final class Builder {
    private final Context mContext;
    private PurchasesUpdatedListener mListener;

    private Builder(Context context) {
      mContext = context;
    }

    /**
     * Specify a valid listener for onPurchasesUpdated event.
     *
     * @param listener Your listener for app initiated and Play Store initiated purchases.
     */
    @UiThread
    public Builder setListener(PurchasesUpdatedListener listener) {
      mListener = listener;
      return this;
    }

    /**
     * Creates a Billing client instance.
     *
     * <p>After creation, it will not yet be ready to use. You must initiate setup by calling {@link
     * #startConnection} and wait for setup to complete.
     *
     * @return BillingClient instance
     * @throws IllegalArgumentException if Context or PurchasesUpdatedListener were not set.
     */
    @UiThread
    public BillingClient build() {
      if (mContext == null) {
        throw new IllegalArgumentException("Please provide a valid Context.");
      }
      if (mListener == null) {
        throw new IllegalArgumentException(
            "Please provide a valid listener for" + " purchases updates.");
      }
      return new BillingClientImpl(mContext, mListener);
    }
  }

  /**
   * Constructs a new {@link Builder} instance.
   *
   * @param context It will be used to get an application context to bind to the in-app billing
   *     service.
   */
  @UiThread
  public static Builder newBuilder(@NonNull Context context) {
    return new Builder(context);
  }

  /**
   * Check if specified feature or capability is supported by the Play Store.
   *
   * @param feature One of {@link FeatureType} constants.
   * @return BILLING_RESULT_OK if feature is supported and corresponding error code otherwise.
   */
  @UiThread
  public abstract @BillingResponse int isFeatureSupported(@FeatureType String feature);

  /**
   * Checks if the client is currently connected to the service, so that requests to other methods
   * will succeed.
   *
   * <p>Returns true if the client is currently connected to the service, false otherwise.
   *
   * <p>Note: It also means that INAPP items are supported for purchasing, queries and all other
   * actions. If you need to check support for SUBSCRIPTIONS or something different, use {@link
   * #isFeatureSupported(String)} method.
   */
  @UiThread
  public abstract boolean isReady();

  /**
   * Starts up BillingClient setup process asynchronously. You will be notified through the {@link
   * BillingClientStateListener} listener when the setup process is complete.
   *
   * @param listener The listener to notify when the setup process is complete.
   */
  @UiThread
  public abstract void startConnection(@NonNull final BillingClientStateListener listener);

  /**
   * Close the connection and release all held resources such as service connections.
   *
   * <p>Call this method once you are done with this BillingClient reference.
   */
  @UiThread
  public abstract void endConnection();

  /**
   * Initiate the billing flow for an in-app purchase or subscription.
   *
   * <p>It will show the Google Play purchase screen. The result will be delivered via the {@link
   * PurchasesUpdatedListener} interface implementation reported to the {@link BillingClientImpl}
   * constructor.
   *
   * @param activity An activity reference from which the billing flow will be launched.
   * @param params Params specific to the request {@link BillingFlowParams}).
   * @return int The response code ({@link BillingResponse}) of launch flow operation.
   */
  @UiThread
  public abstract int launchBillingFlow(Activity activity, BillingFlowParams params);

  /**
   * Get purchases details for all the items bought within your app. This method uses a cache of
   * Google Play Store app without initiating a network request.
   *
   * <p>Note: It's recommended for security purposes to go through purchases verification on your
   * backend (if you have one) by calling the following API:
   * https://developers.google.com/android-publisher/api-ref/purchases/products/get
   *
   * @param skuType The type of SKU, either "inapp" or "subs" as in {@link SkuType}.
   * @return PurchasesResult The {@link PurchasesResult} containing the list of purchases and the
   *     response code ({@link BillingResponse}
   */
  @UiThread
  public abstract PurchasesResult queryPurchases(@SkuType String skuType);

  /**
   * Perform a network query to get SKU details and return the result asynchronously.
   *
   * @param params Params specific to this query request {@link SkuDetailsParams}.
   * @param listener Implement it to get the result of your query operation returned asynchronously
   *     through the callback with the {@link BillingResponse} and the list of {@link SkuDetails}.
   */
  @UiThread
  public abstract void querySkuDetailsAsync(
      SkuDetailsParams params, SkuDetailsResponseListener listener);

  /**
   * Consumes a given in-app product. Consuming can only be done on an item that's owned, and as a
   * result of consumption, the user will no longer own it.
   *
   * <p>Consumption is done asynchronously and the listener receives the callback specified upon
   * completion.
   *
   * @param purchaseToken The purchase token of the item to consume.
   * @param listener Implement it to get the result of your consume operation returned
   *     asynchronously through the callback with token and {@link BillingResponse} parameters.
   */
  @UiThread
  public abstract void consumeAsync(String purchaseToken, ConsumeResponseListener listener);

  /**
   * Returns the most recent purchase made by the user for each SKU, even if that purchase is
   * expired, canceled, or consumed.
   *
   * @param skuType The type of SKU, either "inapp" or "subs" as in {@link SkuType}.
   * @param listener Implement it to get the result of your query returned asynchronously through
   *     the callback with a {@link PurchasesResult} parameter.
   */
  @UiThread
  public abstract void queryPurchaseHistoryAsync(
      @SkuType String skuType, PurchaseHistoryResponseListener listener);
}
