package com.dooboolab.flutterinapppurchase;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import android.os.Handler;
import android.os.Looper;

// MethodChannel.Result wrapper that responds on the platform thread.
public class MethodResultWrapper implements Result {
  private Result safeResult;
  private MethodChannel safeChannel;
  private Handler handler;

  MethodResultWrapper(Result result, MethodChannel channel) {
    safeResult = result;
    safeChannel = channel;
    handler = new Handler(Looper.getMainLooper());
  }

  @Override
  public void success(final Object result) {
    safeResult.success(result);
  }

  @Override
  public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
    safeResult.error(errorCode, errorMessage, errorDetails);
  }

  @Override
  public void notImplemented() {
    safeResult.notImplemented();
  }

  public void invokeMethod(final String method, final Object arguments) {
    safeChannel.invokeMethod(method, arguments, null);
  }
}