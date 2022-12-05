package com.dooboolab.flutterinapppurchase

import android.app.Activity
import android.app.Application
import android.app.Application.ActivityLifecycleCallbacks
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import com.android.billingclient.api.*
import com.android.billingclient.api.BillingFlowParams.*
import io.flutter.plugin.common.FlutterException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * AndroidInappPurchasePlugin
 */
class AndroidInappPurchasePlugin internal constructor() : MethodCallHandler,
    ActivityLifecycleCallbacks {
    private var safeResult: MethodResultWrapper? = null
    private var billingClient: BillingClient? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null
    fun setContext(context: Context?) {
        this.context = context
    }
    fun setActivity(activity: Activity?) {
        this.activity = activity
    }
    fun setChannel(channel: MethodChannel?) {
        this.channel = channel
    }
    fun onDetachedFromActivity() {
        endBillingClientConnection()
    }
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityDestroyed(activity: Activity) {
        if (this.activity === activity && context != null) {
            (context as Application?)!!.unregisterActivityLifecycleCallbacks(this)
            endBillingClientConnection()
        }
    }
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        if(call.method == "getStore"){
            result.success(FlutterInappPurchasePlugin.getStore())
            return
        }

        if(call.method == "manageSubscription"){
            result.success(manageSubscription(call.argument<String>("sku")!!,call.argument<String>("packageName")!!))
            return
        }

        if(call.method == "openPlayStoreSubscriptions"){
            result.success(openPlayStoreSubscriptions())
            return
        }

        safeResult = MethodResultWrapper(result, channel!!)
        val safeChannel = MethodResultWrapper(result, channel!!)

        if (call.method == "initConnection") {
            if (billingClient != null) {
                safeChannel.success("Already started. Call endConnection method if you want to start over.")
                return
            }
            billingClient = BillingClient.newBuilder(context!!).setListener(purchasesUpdatedListener)
                    .enablePendingPurchases()
                    .build()
            billingClient!!.startConnection(object : BillingClientStateListener {
                private var alreadyFinished = false
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    try {
                        val responseCode = billingResult.responseCode
                        if (responseCode == BillingClient.BillingResponseCode.OK) {
                            val item = JSONObject()
                            item.put("connected", true)
                            safeChannel.invokeMethod("connection-updated", item.toString())
                            if (alreadyFinished) return
                            alreadyFinished = true
                            safeChannel.success("Billing client ready")
                            return
                        } else {
                            val item = JSONObject()
                            item.put("connected", false)
                            safeChannel.invokeMethod("connection-updated", item.toString())
                            if (alreadyFinished) return
                            alreadyFinished = true
                            safeChannel.error(call.method, "responseCode: $responseCode", "")
                            return
                        }
                    } catch (je: JSONException) {
                        je.printStackTrace()
                    }
                }

                override fun onBillingServiceDisconnected() {
                    try {
                        val item = JSONObject()
                        item.put("connected", false)
                        safeChannel.invokeMethod("connection-updated", item.toString())
                        return
                    } catch (je: JSONException) {
                        je.printStackTrace()
                    }
                }
            })
            return
        }

        if (call.method == "endConnection") {
            if (billingClient == null) {
                safeChannel.success("Already ended.")
            }else{
                endBillingClientConnection(safeChannel)
            }
            return
        }

        val isReady = billingClient?.isReady

        if(call.method == "isReady"){
            safeChannel.success(isReady)
            return
        }

        if (isReady != true) {
            safeChannel.error(
                call.method,
                BillingError.E_NOT_PREPARED,
                "IAP not prepared. Check if Google Play service is available."
            )
            return
        }

        when(call.method){
            "showInAppMessages" -> showInAppMessages(safeChannel)
            "consumeAllItems" -> consumeAllItems(safeChannel, call)
            "getProducts" -> getProductsByType(BillingClient.ProductType.INAPP, call, safeChannel)
            "getSubscriptions" -> getProductsByType(BillingClient.ProductType.SUBS, call, safeChannel)
            "getAvailableItemsByType" -> getAvailableItemsByType(call, safeChannel)
            "getPurchaseHistoryByType" -> getPurchaseHistoryByType(call, safeChannel)
            "buyItemByType" -> buyProduct(call, safeChannel)
            "acknowledgePurchase" -> acknowledgePurchase(call, safeChannel)
            "consumeProduct" -> consumeProduct(call, safeChannel)
            else -> safeChannel.notImplemented()
        }
    }

    private fun manageSubscription(sku: String, packageName: String): Boolean{
        val url = "$PLAY_STORE_URL?sku=${sku}&package=${packageName}"
        return openWithFallback(Uri.parse(url))
    }

    private fun openPlayStoreSubscriptions():Boolean{
        return openWithFallback(Uri.parse(PLAY_STORE_URL))
    }

    private fun openWithFallback(uri: Uri):Boolean{
        try{
            activity!!.startActivity(Intent(Intent.ACTION_VIEW).apply { data = uri })
            return true
        }catch (e: ActivityNotFoundException){
            try{
                activity!!.startActivity( Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, "text/html")
                    .addCategory(Intent.CATEGORY_BROWSABLE))
                return true
            }catch (e: ActivityNotFoundException){
                // ignore
            }
        }
        return false
    }

    private fun showInAppMessages(safeChannel: MethodResultWrapper) {
        val inAppMessageParams = InAppMessageParams.newBuilder()
            .addInAppMessageCategoryToShow(InAppMessageParams.InAppMessageCategoryId.TRANSACTIONAL)
            .build()

        billingClient!!.showInAppMessages(activity!!, inAppMessageParams) { inAppMessageResult ->
            safeChannel.invokeMethod("on-in-app-message", inAppMessageResult.responseCode)
        }
        safeChannel.success("show in app messages ready")
    }

    private fun consumeAllItems(
        safeChannel: MethodResultWrapper,
        call: MethodCall
    ) {
        try {
            val array = ArrayList<String>()
            val params = QueryPurchasesParams.newBuilder().apply { setProductType(BillingClient.ProductType.INAPP) }.build()
            billingClient!!.queryPurchasesAsync(params)
            { billingResult, productDetailsList ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    if (productDetailsList.size == 0) {
                        safeChannel.error(
                            call.method,
                            "refreshItem",
                            "No purchases found"
                        )
                        return@queryPurchasesAsync
                    }

                    for (purchase in productDetailsList) {
                        val consumeParams = ConsumeParams.newBuilder()
                            .setPurchaseToken(purchase.purchaseToken)
                            .build()
                        val listener = ConsumeResponseListener { _, outToken ->
                            array.add(outToken)
                            if (productDetailsList.size == array.size) {
                                try {
                                    safeChannel.success(array.toString())
                                    return@ConsumeResponseListener
                                } catch (e: FlutterException) {
                                    Log.e(TAG, e.message!!)
                                }
                            }
                        }
                        billingClient!!.consumeAsync(consumeParams, listener)
                    }
                } else {
                    safeChannel.error(
                        call.method, "refreshItem",
                        "No results for query"
                    )
                }
            }

        } catch (err: Error) {
            safeChannel.error(call.method, err.message, "")
        }
    }

    private fun getAvailableItemsByType(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
        val params = QueryPurchasesParams.newBuilder().apply { setProductType(type) }.build()
        val items = JSONArray()
        billingClient!!.queryPurchasesAsync(params) { billingResult, productDetailList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                for (purchase in productDetailList) {
                    val item = JSONObject()
                    item.put("productId", purchase.products[0])
                    item.put("transactionId", purchase.orderId)
                    item.put("transactionDate", purchase.purchaseTime)
                    item.put("transactionReceipt", purchase.originalJson)
                    item.put("purchaseToken", purchase.purchaseToken)
                    item.put("signatureAndroid", purchase.signature)
                    item.put("purchaseStateAndroid", purchase.purchaseState)
                    if (type == BillingClient.ProductType.INAPP) {
                        item.put("isAcknowledgedAndroid", purchase.isAcknowledged)
                    } else if (type == BillingClient.ProductType.SUBS) {
                        item.put("autoRenewingAndroid", purchase.isAutoRenewing)
                    }
                    items.put(item)
                }
                safeChannel.success(items.toString())
            } else {
                safeChannel.error(
                    call.method, billingResult.debugMessage,
                    "responseCode:${billingResult.responseCode}"
                )
            }
        }
    }

    private fun consumeProduct(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val token = call.argument<String>("token")
        val params = ConsumeParams.newBuilder()
            .setPurchaseToken(token!!)
            .build()
        billingClient!!.consumeAsync(params, ConsumeResponseListener { billingResult, _ ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@ConsumeResponseListener
            }
            try {
                val item = JSONObject()
                item.put("responseCode", billingResult.responseCode)
                item.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                item.put("code", errorData.code)
                item.put("message", errorData.message)
                safeChannel.success(item.toString())
                return@ConsumeResponseListener
            } catch (je: JSONException) {
                safeChannel.error(
                    TAG,
                    BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR,
                    je.message
                )
                return@ConsumeResponseListener
            }
        })
    }

    private fun acknowledgePurchase(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val token = call.argument<String>("token")
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(token!!)
            .build()
        billingClient!!.acknowledgePurchase(
            acknowledgePurchaseParams,
            AcknowledgePurchaseResponseListener { billingResult ->
                if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                    safeChannel.error(call.method, errorData.code, errorData.message)
                    return@AcknowledgePurchaseResponseListener
                }
                try {
                    val item = JSONObject()
                    item.put("responseCode", billingResult.responseCode)
                    item.put("debugMessage", billingResult.debugMessage)
                    val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                    item.put("code", errorData.code)
                    item.put("message", errorData.message)
                    safeChannel.success(item.toString())
                } catch (je: JSONException) {
                    je.printStackTrace()
                    safeChannel.error(
                        TAG,
                        BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR,
                        je.message
                    )
                }
            })
    }

    private fun getPurchaseHistoryByType(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
        val params = QueryPurchaseHistoryParams.newBuilder().apply { setProductType(type) }.build()

        billingClient!!.queryPurchaseHistoryAsync(
            params,
            PurchaseHistoryResponseListener { billingResult, purchaseHistoryRecordList ->
                if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                    safeChannel.error(call.method, errorData.code, errorData.message)
                    return@PurchaseHistoryResponseListener
                }
                val items = JSONArray()
                try {
                    for (purchase in purchaseHistoryRecordList!!) {
                        val item = JSONObject()
                        item.put("productId", purchase.products[0])
                        item.put("transactionDate", purchase.purchaseTime)
                        item.put("transactionReceipt", purchase.originalJson)
                        item.put("purchaseToken", purchase.purchaseToken)
                        item.put("dataAndroid", purchase.originalJson)
                        item.put("signatureAndroid", purchase.signature)
                        items.put(item)
                    }
                    safeChannel.success(items.toString())
                    return@PurchaseHistoryResponseListener
                } catch (je: JSONException) {
                    je.printStackTrace()
                    safeChannel.error(TAG, BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR, je.message)
                }
            })
    }

    private fun getProductsByType(
        productType: String,
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val productIds : ArrayList<String> = call.argument<ArrayList<String>>("productIds")!!
        val params = ArrayList<QueryProductDetailsParams.Product>()
        for (i in productIds.indices) {
            params.add(QueryProductDetailsParams.Product.newBuilder().setProductId(productIds[i]).setProductType(productType).build())
        }

        billingClient!!.queryProductDetailsAsync(
            QueryProductDetailsParams.newBuilder().setProductList(params).build()
        ) { billingResult, products ->
            // On error
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@queryProductDetailsAsync
            }

            try {
                val items = JSONArray()
                for (productDetails in products) {
                    // Add to list of tracked products
                    if (!productDetailsList.contains(productDetails)) {
                        productDetailsList.add(productDetails)
                    }

                    // Create flutter objects
                    val item = JSONObject()
                    item.put("productId", productDetails.productId)
                    item.put("type", productDetails.productType)
                    item.put("title", productDetails.title)
                    item.put("description", productDetails.description)

                    // One-time offer details have changed in 5.0
                    if (productDetails.oneTimePurchaseOfferDetails != null) {
                        item.put("introductoryPrice", productDetails.oneTimePurchaseOfferDetails!!.formattedPrice)
                    }

                    // These generalized values are derived from the first pricing object, mainly for backwards compatibility
                    // It would be better to use the actual objects in PricingPhases and SubscriptionOffers

                    // Get first subscription offer
                    val firstProductInfo = productDetails.subscriptionOfferDetails?.find { offer -> offer.offerId == null }
                    if (firstProductInfo != null && firstProductInfo.pricingPhases.pricingPhaseList[0] != null) {
                        val defaultPricingPhase = firstProductInfo.pricingPhases.pricingPhaseList[0]
                        item.put("price", (defaultPricingPhase.priceAmountMicros / 1000000f).toString())
                        item.put("currency", defaultPricingPhase.priceCurrencyCode)
                        item.put("localizedPrice", defaultPricingPhase.formattedPrice)
                        item.put("subscriptionPeriodAndroid", defaultPricingPhase.billingPeriod)
                    }

                    val subs = JSONArray()
                    if (productDetails.subscriptionOfferDetails != null ) {
                        for (offer in productDetails.subscriptionOfferDetails!!) {
                            val offerItem = JSONObject()
                            offerItem.put("offerId", offer.offerId)
                            offerItem.put("basePlanId", offer.basePlanId)
                            offerItem.put("offerToken", offer.offerToken)
                            val pricingPhases = JSONArray()
                            for (pricing in offer.pricingPhases.pricingPhaseList) {
                                val pricingPhase = JSONObject()
                                pricingPhase.put("price", (pricing.priceAmountMicros / 1000000f).toString())
                                pricingPhase.put("formattedPrice", pricing.formattedPrice)
                                pricingPhase.put("billingPeriod", pricing.billingPeriod)
                                pricingPhase.put("currencyCode", pricing.priceCurrencyCode)
                                pricingPhase.put("recurrenceMode", pricing.recurrenceMode)
                                pricingPhase.put("billingCycleCount", pricing.billingCycleCount)
                                pricingPhases.put(pricingPhase)
                            }
                            offerItem.put("pricingPhases", pricingPhases)
                            subs.put(offerItem)
                        }
                    }
                    item.put("subscriptionOffers", subs)
                    items.put(item)
                }
                safeChannel.success(items.toString())
                return@queryProductDetailsAsync
            } catch (je: JSONException) {
                je.printStackTrace()
                safeChannel.error(TAG, BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR, je.message)
            } catch (fe: FlutterException) {
                safeChannel.error(call.method, fe.message, fe.localizedMessage)
                return@queryProductDetailsAsync
            }
        }
    }

    private fun buyProduct(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        try {
            val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
            val obfuscatedAccountId = call.argument<String>("obfuscatedAccountId")
            val obfuscatedProfileId = call.argument<String>("obfuscatedProfileId")
            val productId = call.argument<String>("productId")
            val prorationMode = call.argument<Int>("prorationMode")!!
            val purchaseToken = call.argument<String>("purchaseToken")
            val offerTokenIndex = call.argument<Int>("offerTokenIndex")
            val builder = newBuilder()
            var selectedProductDetails: ProductDetails? = null
            for (productDetails in productDetailsList) {
                if (productDetails.productId == productId) {
                    selectedProductDetails = productDetails
                    break
                }
            }
            if (selectedProductDetails == null) {
                val debugMessage =
                    "The selected product was not found. Please fetch setObfuscatedAccountIdproducts first by calling getItems"
                safeChannel.error(TAG, "buyItemByType", debugMessage)
                return
            }

            // Get the selected offerToken from the product, or first one if this is a migrated from 4.0 product
            // or if the offerTokenIndex was not provided
            var offerToken : String? = null
            if (offerTokenIndex != null) {
                offerToken = selectedProductDetails.subscriptionOfferDetails?.get(offerTokenIndex)?.offerToken
            }
            if (offerToken == null) {
                offerToken = selectedProductDetails.subscriptionOfferDetails!![0].offerToken
            }

            val productDetailsParamsList =
            listOf(ProductDetailsParams.newBuilder()
                .setProductDetails(selectedProductDetails)
                .setOfferToken(offerToken)
                .build())
            builder.setProductDetailsParamsList(productDetailsParamsList)

            val params = SubscriptionUpdateParams.newBuilder()

            if (obfuscatedAccountId != null) {
                builder.setObfuscatedAccountId(obfuscatedAccountId)
            }
            if (obfuscatedProfileId != null) {
                builder.setObfuscatedProfileId(obfuscatedProfileId)
            }

            when (prorationMode) {
                -1 -> {} //ignore
                ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE -> {
                    params.setReplaceProrationMode(ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE)
                    if (type != BillingClient.ProductType.SUBS) {
                        safeChannel.error(
                            TAG,
                            "buyItemByType",
                            "IMMEDIATE_AND_CHARGE_PRORATED_PRICE for proration mode only works in subscription purchase."
                        )
                        return
                    }
                }
                ProrationMode.IMMEDIATE_WITHOUT_PRORATION,
                ProrationMode.DEFERRED,
                ProrationMode.IMMEDIATE_WITH_TIME_PRORATION,
                ProrationMode.IMMEDIATE_AND_CHARGE_FULL_PRICE ->
                    params.setReplaceProrationMode(prorationMode)
                else -> params.setReplaceProrationMode(ProrationMode.UNKNOWN_SUBSCRIPTION_UPGRADE_DOWNGRADE_POLICY)
            }

            if (purchaseToken != null) {
                params.setOldPurchaseToken(purchaseToken)
                builder.setSubscriptionUpdateParams(params.build())
            }
            if (activity != null) {
                billingClient!!.launchBillingFlow(activity!!, builder.build())

            }
        } catch (e: Exception) {
            safeChannel.error(TAG, "buyItemByType", e.message)
            return
        }
    }

    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        try {
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val json = JSONObject()
                json.put("responseCode", billingResult.responseCode)
                json.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                json.put("code", errorData.code)
                json.put("message", errorData.message)
                safeResult!!.invokeMethod("purchase-error", json.toString())
                return@PurchasesUpdatedListener
            }
            if (purchases != null) {
                for (purchase in purchases) {
                    val item = JSONObject()
                    item.put("productId", purchase.products[0])
                    item.put("transactionId", purchase.orderId)
                    item.put("transactionDate", purchase.purchaseTime)
                    item.put("transactionReceipt", purchase.originalJson)
                    item.put("purchaseToken", purchase.purchaseToken)
                    item.put("dataAndroid", purchase.originalJson)
                    item.put("signatureAndroid", purchase.signature)
                    item.put("purchaseStateAndroid", purchase.purchaseState)
                    item.put("autoRenewingAndroid", purchase.isAutoRenewing)
                    item.put("isAcknowledgedAndroid", purchase.isAcknowledged)
                    item.put("packageNameAndroid", purchase.packageName)
                    item.put("developerPayloadAndroid", purchase.developerPayload)
                    val accountIdentifiers = purchase.accountIdentifiers
                    if (accountIdentifiers != null) {
                        item.put("obfuscatedAccountIdAndroid", accountIdentifiers.obfuscatedAccountId)
                        item.put("obfuscatedProfileIdAndroid", accountIdentifiers.obfuscatedProfileId)
                    }
                    safeResult!!.invokeMethod("purchase-updated", item.toString())
                    return@PurchasesUpdatedListener
                }
            } else {
                val json = JSONObject()
                json.put("responseCode", billingResult.responseCode)
                json.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                json.put("code", errorData.code)
                json.put("message", "purchases returns null.")
                safeResult!!.invokeMethod("purchase-error", json.toString())
                return@PurchasesUpdatedListener
            }
        } catch (je: JSONException) {
            safeResult!!.invokeMethod("purchase-error", je.message)
            return@PurchasesUpdatedListener
        }
    }

    private fun endBillingClientConnection(safeChannel: MethodResultWrapper? = null) {
        try {
            billingClient?.endConnection()
            billingClient = null
            safeChannel?.success("Billing client has ended.")
        } catch (e: Exception) {
            safeChannel?.error("client end connection", e.message, "")
        }
    }

    companion object {
        private const val TAG = "InappPurchasePlugin"
        private const val PLAY_STORE_URL = "https://play.google.com/store/account/subscriptions"
        private var productDetailsList: ArrayList<ProductDetails> = arrayListOf()
    }
}