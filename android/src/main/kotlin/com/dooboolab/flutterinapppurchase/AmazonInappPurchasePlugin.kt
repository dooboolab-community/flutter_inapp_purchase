package com.dooboolab.flutterinapppurchase

import android.app.Activity
import android.content.Context
import android.util.Log
import com.amazon.device.iap.PurchasingListener
import com.amazon.device.iap.PurchasingService
import com.amazon.device.iap.model.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/** AmazonInappPurchasePlugin  */
class AmazonInappPurchasePlugin : MethodCallHandler {
    private val TAG = "InappPurchasePlugin"
    private var safeResult: MethodResultWrapper? = null
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null
    fun setContext(context: Context?) {
        this.context = context
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun setChannel(channel: MethodChannel?) {
        this.channel = channel
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if(call.method == "getStore"){
            result.success(FlutterInappPurchasePlugin.getStore())
            return
        }

        safeResult = MethodResultWrapper(result, channel!!)

        try {
            PurchasingService.registerListener(context, purchasesUpdatedListener)
        } catch (e: Exception) {
            safeResult!!.error(
                call.method,
                "Call endConnection method if you want to start over.",
                e.message
            )
        }
        when (call.method) {
            "initConnection" -> {
                PurchasingService.getUserData()
                safeResult!!.success("Billing client ready")
            }
            "endConnection" -> {
                safeResult!!.success("Billing client has ended.")
            }
            "isReady" -> {
                safeResult!!.success(true)
            }
            "showInAppMessages" -> {
                safeResult!!.success("in app messages not supported for amazon")
            }
            "consumeAllItems" -> {
                // consumable is a separate type in amazon
                safeResult!!.success("no-ops in amazon")
            }
            "getProducts",
            "getSubscriptions" -> {
                Log.d(TAG, call.method)
                val skus = call.argument<ArrayList<String>>("skus")!!
                val productSkus: MutableSet<String> = HashSet()
                for (i in skus.indices) {
                    Log.d(TAG, "Adding " + skus[i])
                    productSkus.add(skus[i])
                }
                PurchasingService.getProductData(productSkus)
            }
            "getAvailableItemsByType" -> {
                val type = call.argument<String>("type")
                Log.d(TAG, "gaibt=$type")
                // NOTE: getPurchaseUpdates doesnt return Consumables which are FULFILLED
                if (type == "inapp") {
                    PurchasingService.getPurchaseUpdates(true)
                } else if (type == "subs") {
                    // Subscriptions are retrieved during inapp, so we just return empty list
                    safeResult!!.success("[]")
                } else {
                    safeResult!!.notImplemented()
                }
            }
            "getPurchaseHistoryByType" -> {
                // No equivalent
                safeResult!!.success("[]")
            }
            "buyItemByType" -> {
                val type = call.argument<String>("type")
                //val obfuscatedAccountId = call.argument<String>("obfuscatedAccountId")
                //val obfuscatedProfileId = call.argument<String>("obfuscatedProfileId")
                val sku = call.argument<String>("sku")
                val oldSku = call.argument<String>("oldSku")
                //val prorationMode = call.argument<Int>("prorationMode")!!
                Log.d(TAG, "type=$type||sku=$sku||oldsku=$oldSku")
                val requestId = PurchasingService.purchase(sku)
                Log.d(TAG, "resid=$requestId")
            }
            "consumeProduct" -> {
                // consumable is a separate type in amazon
                safeResult!!.success("no-ops in amazon")
            }
            else -> {
                safeResult!!.notImplemented()
            }
        }
    }

    private val purchasesUpdatedListener: PurchasingListener = object : PurchasingListener {
        override fun onUserDataResponse(userDataResponse: UserDataResponse) {
            Log.d(TAG, "oudr=$userDataResponse")
        }

        // getItemsByType
        override fun onProductDataResponse(response: ProductDataResponse) {
            Log.d(TAG, "opdr=$response")
            val status = response.requestStatus
            Log.d(TAG, "onProductDataResponse: RequestStatus ($status)")
            when (status) {
                ProductDataResponse.RequestStatus.SUCCESSFUL -> {
                    Log.d(
                        TAG,
                        "onProductDataResponse: successful.  The item data map in this response includes the valid SKUs"
                    )
                    val productData = response.productData
                    //Log.d(TAG, "productData="+productData.toString());
                    val unavailableSkus = response.unavailableSkus
                    Log.d(
                        TAG,
                        "onProductDataResponse: " + unavailableSkus.size + " unavailable skus"
                    )
                    Log.d(TAG, "unavailableSkus=$unavailableSkus")
                    val items = JSONArray()
                    try {
                        for ((_, product) in productData) {
                            //val format = NumberFormat.getCurrencyInstance()
                            val item = JSONObject()
                            item.put("productId", product.sku)
                            item.put("price", product.price)
                            item.put("currency", null)
                            when (product.productType) {
                                ProductType.ENTITLED, ProductType.CONSUMABLE -> item.put(
                                    "type",
                                    "inapp"
                                )
                                ProductType.SUBSCRIPTION -> item.put("type", "subs")
                            }
                            item.put("localizedPrice", product.price)
                            item.put("title", product.title)
                            item.put("description", product.description)
                            item.put("introductoryPrice", "")
                            item.put("subscriptionPeriodAndroid", "")
                            item.put("freeTrialPeriodAndroid", "")
                            item.put("introductoryPriceCyclesAndroid", 0)
                            item.put("introductoryPricePeriodAndroid", "")
                            Log.d(TAG, "opdr Putting $item")
                            items.put(item)
                        }
                        //System.err.println("Sending "+items.toString());
                        safeResult!!.success(items.toString())
                    } catch (e: JSONException) {
                        safeResult!!.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.message)
                    }
                }
                ProductDataResponse.RequestStatus.FAILED -> {
                    safeResult!!.error(TAG, "FAILED", null)
                    Log.d(TAG, "onProductDataResponse: failed, should retry request")
                    safeResult!!.error(TAG, "NOT_SUPPORTED", null)
                }
                ProductDataResponse.RequestStatus.NOT_SUPPORTED -> {
                    Log.d(TAG, "onProductDataResponse: failed, should retry request")
                    safeResult!!.error(TAG, "NOT_SUPPORTED", null)
                }
            }
        }

        // buyItemByType
        override fun onPurchaseResponse(response: PurchaseResponse) {
            Log.d(TAG, "opr=$response")
            when (val status = response.requestStatus) {
                PurchaseResponse.RequestStatus.SUCCESSFUL -> {
                    val receipt = response.receipt
                    PurchasingService.notifyFulfillment(
                        receipt.receiptId,
                        FulfillmentResult.FULFILLED
                    )
                    val date = receipt.purchaseDate
                    val transactionDate = date.time
                    try {
                        val item = getPurchaseData(
                            receipt.sku,
                            receipt.receiptId,
                            receipt.receiptId,
                            transactionDate.toDouble()
                        )
                        Log.d(TAG, "opr Putting $item")
                        safeResult!!.success(item.toString())
                        safeResult!!.invokeMethod("purchase-updated", item.toString())
                    } catch (e: JSONException) {
                        safeResult!!.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.message)
                    }
                }
                PurchaseResponse.RequestStatus.FAILED -> safeResult!!.error(
                    TAG,
                    "buyItemByType",
                    "billingResponse is not ok: $status"
                )
                else -> {}
            }
        }

        // getAvailableItemsByType
        override fun onPurchaseUpdatesResponse(response: PurchaseUpdatesResponse) {
            Log.d(TAG, "opudr=$response")
            when (response.requestStatus) {
                PurchaseUpdatesResponse.RequestStatus.SUCCESSFUL -> {
                    val items = JSONArray()
                    try {
                        val receipts = response.receipts
                        for (receipt in receipts) {
                            val date = receipt.purchaseDate
                            val transactionDate = date.time
                            val item = getPurchaseData(
                                receipt.sku,
                                receipt.receiptId,
                                receipt.receiptId,
                                transactionDate.toDouble()
                            )
                            Log.d(TAG, "opudr Putting $item")
                            items.put(item)
                        }
                        safeResult!!.success(items.toString())
                    } catch (e: JSONException) {
                        safeResult!!.error(TAG, "E_BILLING_RESPONSE_JSON_PARSE_ERROR", e.message)
                    }
                }
                PurchaseUpdatesResponse.RequestStatus.FAILED -> safeResult!!.error(
                    TAG,
                    "FAILED",
                    null
                )
                PurchaseUpdatesResponse.RequestStatus.NOT_SUPPORTED -> {
                    Log.d(TAG, "onPurchaseUpdatesResponse: failed, should retry request")
                    safeResult!!.error(TAG, "NOT_SUPPORTED", null)
                }
            }
        }
    }

    @Throws(JSONException::class)
    fun getPurchaseData(
        productId: String?, transactionId: String?, transactionReceipt: String?,
        transactionDate: Double?
    ): JSONObject {
        val item = JSONObject()
        item.put("productId", productId)
        item.put("transactionId", transactionId)
        item.put("transactionReceipt", transactionReceipt)
        item.put("transactionDate", (transactionDate!!).toString())
        item.put("dataAndroid", null)
        item.put("signatureAndroid", null)
        item.put("purchaseToken", null)
        return item
    }
}