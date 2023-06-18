package com.dooboolab.flutterinapppurchase

import android.os.Handler
import io.flutter.plugin.common.MethodChannel
import android.os.Looper

// MethodChannel.Result wrapper that responds on the platform thread.
class MethodResultWrapper internal constructor(
    private val safeResult: MethodChannel.Result,
    private val safeChannel: MethodChannel
) : MethodChannel.Result {
    private val handler: Handler = Handler(Looper.getMainLooper())
    private var exhausted: Boolean = false
    override fun success(result: Any?) {
        if (!exhausted) {
            exhausted = true

            handler.post { safeResult.success(result) }
        }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        if (!exhausted) {
            exhausted = true

            handler.post { safeResult.error(errorCode, errorMessage, errorDetails) }
        }
    }

    override fun notImplemented() {
        if (!exhausted) {
            exhausted = true

            handler.post { safeResult.notImplemented() }
        }
    }

    fun invokeMethod(method: String?, arguments: Any?) {
        handler.post { safeChannel.invokeMethod(method!!, arguments, null) }
    }

}