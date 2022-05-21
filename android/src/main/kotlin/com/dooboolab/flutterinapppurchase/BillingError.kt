package com.dooboolab.flutterinapppurchase

import android.util.Log
import com.android.billingclient.api.BillingClient.BillingResponseCode

class BillingError {
    companion object {
        private const val TAG = "DoobooUtils"
        private const val E_UNKNOWN = "E_UNKNOWN"
        const val E_NOT_PREPARED = "E_NOT_PREPARED"
        private const val E_NOT_ENDED = "E_NOT_ENDED"
        private const val E_USER_CANCELLED = "E_USER_CANCELLED"
        private const val E_ITEM_UNAVAILABLE = "E_ITEM_UNAVAILABLE"
        private const val E_NETWORK_ERROR = "E_NETWORK_ERROR"
        private const val E_SERVICE_ERROR = "E_SERVICE_ERROR"
        private const val E_ALREADY_OWNED = "E_ALREADY_OWNED"
        private const val E_REMOTE_ERROR = "E_REMOTE_ERROR"
        private const val E_USER_ERROR = "E_USER_ERROR"
        private const val E_DEVELOPER_ERROR = "E_DEVELOPER_ERROR"
        const val E_BILLING_RESPONSE_JSON_PARSE_ERROR = "E_BILLING_RESPONSE_JSON_PARSE_ERROR"

        fun getErrorFromResponseData(responseCode: Int): ErrorData {
            Log.e(TAG, "Error Code : $responseCode")
            return when (responseCode) {
                BillingResponseCode.FEATURE_NOT_SUPPORTED ->
                    ErrorData(E_SERVICE_ERROR,"This feature is not available on your device.")
                BillingResponseCode.SERVICE_DISCONNECTED ->
                    ErrorData(E_NETWORK_ERROR, "The service is disconnected (check your internet connection.)")
                BillingResponseCode.OK -> ErrorData("OK","")
                BillingResponseCode.USER_CANCELED ->
                    ErrorData(E_USER_CANCELLED, "Payment is Cancelled.")
                BillingResponseCode.SERVICE_UNAVAILABLE ->
                    ErrorData(E_SERVICE_ERROR, "The service is unreachable. This may be your internet connection, or the Play Store may be down.")
                BillingResponseCode.BILLING_UNAVAILABLE ->
                    ErrorData(E_SERVICE_ERROR, "Billing is unavailable. This may be a problem with your device, or the Play Store may be down.")
                BillingResponseCode.ITEM_UNAVAILABLE ->
                    ErrorData( E_ITEM_UNAVAILABLE, "That item is unavailable.")
                BillingResponseCode.DEVELOPER_ERROR ->
                    ErrorData(E_DEVELOPER_ERROR, "Google is indicating that we have some issue connecting to payment.")
                BillingResponseCode.ERROR ->
                    ErrorData(E_UNKNOWN,"An unknown or unexpected error has occured. Please try again later.")
                BillingResponseCode.ITEM_ALREADY_OWNED ->
                    ErrorData(E_ALREADY_OWNED, "You already own this item.")
                else -> ErrorData(E_UNKNOWN,"Purchase failed with code: $responseCode")
            }
        }
    }
}

data class ErrorData(val code: String, val message: String)