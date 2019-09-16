package com.dooboolab.flutterinapppurchase;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterInappPurchasePlugin */
public class FlutterInappPurchasePlugin implements MethodCallHandler {
  static AndroidInappPurchasePlugin androidPlugin;
  static AmazonInappPurchasePlugin amazonPlugin;
  private static  Registrar mRegistrar;

  FlutterInappPurchasePlugin() {
    androidPlugin = new AndroidInappPurchasePlugin();
    amazonPlugin = new AmazonInappPurchasePlugin();
  }

  // Plugin registration.
  public static void registerWith(Registrar registrar) {
    mRegistrar = registrar;
    if(isPackageInstalled(mRegistrar.context(), "com.android.vending")) {
      androidPlugin.registerWith(registrar);
    } else if(isPackageInstalled(mRegistrar.context(), "com.amazon.venezia")) {
      amazonPlugin.registerWith(registrar);
    }

  }

  @Override
  public void onMethodCall(final MethodCall call, final Result result) {
    if(isPackageInstalled(mRegistrar.context(), "com.android.vending")) {
      androidPlugin.onMethodCall(call, result);
    } else if(isPackageInstalled(mRegistrar.context(), "com.amazon.venezia")) {
      amazonPlugin.onMethodCall(call, result);
    } else result.notImplemented();
  }

  public static final boolean isPackageInstalled(Context ctx, String packageName) {
    try {
      ctx.getPackageManager().getPackageInfo(packageName, 0);
    } catch (PackageManager.NameNotFoundException e) {
      return false;
    }
    return true;
  }
}
