package com.dooboolab.flutterinapppurchase;

import android.content.Context;
import android.content.pm.PackageManager;

import java.util.ArrayList;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterInappPurchasePlugin */
public class FlutterInappPurchasePlugin implements FlutterPlugin, ActivityAware {
  private AndroidInappPurchasePlugin androidInappPurchasePlugin;
  private AmazonInappPurchasePlugin amazonInappPurchasePlugin;
  private Context context;
  private MethodChannel channel;

  private static boolean isAndroid;
  private static boolean isAmazon;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    onAttached(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  private void onAttached(Context context, BinaryMessenger messenger) {
    isAndroid = isPackageInstalled(context, "com.android.vending");
    isAmazon = isPackageInstalled(context, "com.amazon.venezia");

    // In the case of an amazon device which has been side loaded with the Google Play store,
    // we should use the store the app was installed from.
    if (isAmazon && isAndroid) {
      if (isAppInstalledFrom(context, "amazon")) {
        isAndroid = false;
      } else {
        isAmazon = false;
      }
    }

    channel = new MethodChannel(messenger, "flutter_inapp");

    if (isAndroid) {
      androidInappPurchasePlugin = new AndroidInappPurchasePlugin();
      androidInappPurchasePlugin.setContext(context);
      androidInappPurchasePlugin.setChannel(channel);
      channel.setMethodCallHandler(androidInappPurchasePlugin);
    } else if (isAmazon) {
      amazonInappPurchasePlugin = new AmazonInappPurchasePlugin();
      amazonInappPurchasePlugin.setContext(context);
      amazonInappPurchasePlugin.setChannel(channel);
      channel.setMethodCallHandler(amazonInappPurchasePlugin);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;

    if (isAndroid) {
      androidInappPurchasePlugin.setChannel(null);
    } else if (isAmazon) {
      amazonInappPurchasePlugin.setChannel(null);
    }
  }

  public static void registerWith(Registrar registrar) {
    FlutterInappPurchasePlugin instance = new FlutterInappPurchasePlugin();
    instance.onAttached(registrar.context(), registrar.messenger());
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    if (isAndroid) {
      androidInappPurchasePlugin.setActivity(binding.getActivity());
    } else if (isAmazon) {
      amazonInappPurchasePlugin.setActivity(binding.getActivity());
    }
  }

  @Override
  public void onDetachedFromActivity() {
    if (isAndroid) {
      androidInappPurchasePlugin.setActivity(null);
      androidInappPurchasePlugin.onDetachedFromActivity();
    } else if (isAmazon) {
      amazonInappPurchasePlugin.setActivity(null);
    }
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  private static boolean isPackageInstalled(Context ctx, String packageName) {
    try {
      ctx.getPackageManager().getPackageInfo(packageName, 0);
      return true;
    } catch (PackageManager.NameNotFoundException e) {
      return false;
    }
  }

  public static final boolean isAppInstalledFrom(Context ctx, String installer) {
    String installerPackageName = ctx.getPackageManager().getInstallerPackageName(ctx.getPackageName());
    return (installer != null && installerPackageName != null && installerPackageName.contains(installer));
  }

  private void setAndroidInappPurchasePlugin(AndroidInappPurchasePlugin androidInappPurchasePlugin) {
    this.androidInappPurchasePlugin = androidInappPurchasePlugin;
  }

  private void setAmazonInappPurchasePlugin(AmazonInappPurchasePlugin amazonInappPurchasePlugin) {
    this.amazonInappPurchasePlugin = amazonInappPurchasePlugin;
  }
}
