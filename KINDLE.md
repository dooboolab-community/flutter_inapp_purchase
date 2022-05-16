# Amazon Kindle Fire / Fire TV In-App Purchases Guide

The plugin will automatically detect Amazon devices during runtime.

## Testing In-App Purchases

To test your purchases, you do not need to create an Amazon developer account.

Install the Amazon App Tester (AAT) :
[Amazon App Tester](https://www.amazon.com/Amazon-App-Tester/dp/B00BN3YZM2)

You need to create an amazon.sdktester.json file. 

Example : [amazon.sdktester.json](https://github.com/dooboolab/flutter_inapp_purchase/blob/main/ancillary/amazon.sdktester.json)
Edit this to add your own Product Ids. 

Put this file into the kindle sdcard with :

    adb push amazon.sdktester.json /sdcard/
    
You can verify if the file is valid in the AAT and view the purchases.

Add android.permission.INTERNET and com.amazon.device.iap.ResponseReceiver to your AndroidManifest like in the example https://github.com/dooboolab/flutter_inapp_purchase/blob/main/example/android/app/src/main/AndroidManifest.xml.

Now, when you make a purchase the AAT will intercept, show the purchases screen and allow you to make a purchase. Your app will think a real purchase has been made and you can test the full purchase flow.

## Testing Live Purchases
Add your apk into the "Live App Testing" tab. Add your IAP into the "In-App Items" tab. You must fill in your bank details first and submit your IAP so that the status is "live".

Also with Gradle 3.4.0 or higher you need to take care of the obfuscating. To do so, create a Proguard file named "proguard-rules.pro" in the android/app folder. Into that file put the following content:

-dontwarn com.amazon.** <br>
-keep class com.amazon.** {*;} <br>
-keepattributes *Annotation* <br>

Then edit your build.gradle in app level like:

build.gradle:

    buildTypes {  
        release {
            shrinkResources false
            signingConfig signingConfigs.release
            minifyEnabled false
            useProguard true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    

If you need more help, check out https://stackoverflow.com/questions/62833628/how-to-disable-code-obfuscation-in-flutter-release-apk and the amazon part https://developer.amazon.com/de/docs/in-app-purchasing/iap-obfuscate-the-code.html.

Now your testers will be sent a link to the test version of your app. They can make purchases at no cost to test your app.

## Submitting to the Amazon store
Amazon developer accounts are free. I found the Amazon store the easiest to submit to (compared with Googles play & Apple store). Required screenshots are the same size as a Nexus 7 so that is what I used.

I found the staff who checked my app very helpful (such as providing logcat output on request for example). Text is the same as other stores, except there is an additional up-to 10 bullet point summary of your app you can add.

When you submit your app to the store there will be a warning that google billing is detected in your code. When you submit your app for approval you can mention in the testing instructions for the Amazon reviewer that you are using a cross-platform tool and the google IAP code is not used. I dont know if this is necessary but my app was approved anyway.
