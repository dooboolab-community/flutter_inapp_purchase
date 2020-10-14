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
    context = binding.getApplicationContext();
    isAndroid = isPackageInstalled(context, "com.android.vending");
    isAmazon = isPackageInstalled(context, "com.amazon.venezia");

    if (isAndroid) {
      androidInappPurchasePlugin = new AndroidInappPurchasePlugin();
      androidInappPurchasePlugin.setContext(context);

      setupMethodChannel(binding.getBinaryMessenger(), androidInappPurchasePlugin);

    } else if(isAmazon) {
      amazonInappPurchasePlugin = new AmazonInappPurchasePlugin();
      amazonInappPurchasePlugin.setContext(context);

      setupMethodChannel(binding.getBinaryMessenger(), amazonInappPurchasePlugin);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (isPackageInstalled(context, "com.android.vending")) {
      tearDownChannel();
    } else if(isPackageInstalled(context, "com.amazon.venezia")) {
      tearDownChannel();
    }
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    FlutterInappPurchasePlugin plugin = new FlutterInappPurchasePlugin();
    if(isAndroid) {
      AndroidInappPurchasePlugin androidInappPurchasePlugin = new AndroidInappPurchasePlugin();
      androidInappPurchasePlugin.setContext(registrar.context());
      androidInappPurchasePlugin.setActivity(registrar.activity());

      plugin.setupMethodChannel(registrar.messenger(), androidInappPurchasePlugin);
      plugin.setAndroidInappPurchasePlugin(androidInappPurchasePlugin);
    } else if(isAmazon) {
      AmazonInappPurchasePlugin amazonInappPurchasePlugin = new AmazonInappPurchasePlugin();
      amazonInappPurchasePlugin.setContext(registrar.context());
      amazonInappPurchasePlugin.setActivity(registrar.activity());

      plugin.setupMethodChannel(registrar.messenger(), amazonInappPurchasePlugin);
      plugin.setAmazonInappPurchasePlugin(amazonInappPurchasePlugin);
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    if (isPackageInstalled(context, "com.android.vending")) {
      androidInappPurchasePlugin.setActivity(binding.getActivity());
    } else if(isPackageInstalled(context, "com.amazon.venezia")) {
      amazonInappPurchasePlugin.setActivity(binding.getActivity());
    }
  }

  @Override
  public void onDetachedFromActivity() {
    if (isPackageInstalled(context, "com.android.vending")) {
      androidInappPurchasePlugin.setActivity(null);
      androidInappPurchasePlugin.onDetachedFromActivity();
    } else if(isPackageInstalled(context, "com.amazon.venezia")) {
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
    } catch (PackageManager.NameNotFoundException e) {
      return false;
    }
    return true;
  }

  private void setupMethodChannel(BinaryMessenger messenger, MethodChannel.MethodCallHandler handler) {
    channel = new MethodChannel(messenger, "flutter_inapp");
    channel.setMethodCallHandler(handler);
    setChannelByPlatform(channel);
  }

  private void tearDownChannel() {
    channel.setMethodCallHandler(null);
    channel = null;
    setChannelByPlatform(null);
  }

  private void setChannelByPlatform(MethodChannel channel) {
    if(isAndroid) {
      androidInappPurchasePlugin.setChannel(channel);
    } else if (isAmazon) {
      amazonInappPurchasePlugin.setChannel(channel);
    }
  }

  private void setAndroidInappPurchasePlugin(AndroidInappPurchasePlugin androidInappPurchasePlugin) {
    this.androidInappPurchasePlugin = androidInappPurchasePlugin;
  }

  private void setAmazonInappPurchasePlugin(AmazonInappPurchasePlugin amazonInappPurchasePlugin) {
    this.amazonInappPurchasePlugin = amazonInappPurchasePlugin;
  }
}
