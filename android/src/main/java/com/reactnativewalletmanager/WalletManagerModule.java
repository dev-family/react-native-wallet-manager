package com.reactnativewalletmanager;

import androidx.annotation.NonNull;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener; 
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.pay.PayClient;
import com.google.android.gms.pay.Pay;
import com.google.android.gms.pay.PayApiAvailabilityStatus;

@ReactModule(name = WalletManagerModule.NAME)
public class WalletManagerModule extends ReactContextBaseJavaModule {
    public static final String NAME = "WalletManager";
    private final PayClient walletClient;
    private static final int addToGoogleWalletRequestCode = 1001;
    private Promise addPassPromise;

    public WalletManagerModule(@NonNull ReactApplicationContext reactContext) {
        super(reactContext);
        walletClient = Pay.getClient(reactContext);
        reactContext.addActivityEventListener(mActivityEventListener); 
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void canAddPasses(final Promise promise) {
        walletClient.getPayApiAvailabilityStatus(PayClient.RequestType.SAVE_PASSES)
                .addOnSuccessListener(new OnSuccessListener<Integer>() {
                    @Override
                    public void onSuccess(Integer status) {
                        if (status == PayApiAvailabilityStatus.AVAILABLE) {
                            promise.resolve(true);
                        } else {
                            promise.resolve(false);
                        }
                    }
                })
                .addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        promise.reject("ERROR", "Error when checking the availability of the Google Wallet API: " + e.getMessage(), e);
                    }
                });
    }

   @ReactMethod
public void addPassToGoogleWallet(String jwt, Promise promise) {
    Activity activity = getCurrentActivity();
    if (activity != null) {
        this.addPassPromise = promise; 
        try {
            walletClient.savePassesJwt(jwt, activity, addToGoogleWalletRequestCode);
            
        } catch (Exception e) {
            e.printStackTrace();
           
            if (e instanceof com.google.android.gms.common.api.ApiException) {
                ApiException apiException = (ApiException) e;
                int statusCode = apiException.getStatusCode();
                String statusMessage = com.google.android.gms.common.api.CommonStatusCodes.getStatusCodeString(statusCode);
                promise.reject("API_ERROR", "Google Pay API error occurred. Status code: " + statusCode + ", Message: " + statusMessage);
            } else {
                promise.reject("GENERAL_ERROR", "Error when saving to Google Wallet: " + e.getMessage(), e);
            }
            this.addPassPromise = null; 
        }
    } else {
        String errorMessage = "Current activity is unavailable.";
        promise.reject("NO_ACTIVITY", errorMessage);
    }
}

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            if (requestCode == addToGoogleWalletRequestCode) {
                if (addPassPromise != null) {
                    switch (resultCode) {
                        case Activity.RESULT_OK:
                            addPassPromise.resolve("Pass successfully added to Google Wallet");
                            break;
                        case Activity.RESULT_CANCELED:
                            addPassPromise.reject("RESULT_CANCELED", "The operation was canceled by the user.");
                            break;
                        default:
                            String error = data != null ? data.getStringExtra("error") : "Unknown error";
                            addPassPromise.reject("UNKNOWN_ERROR", "An error occurred: " + error);
                            break;
                    }
                    addPassPromise = null; 
                }
            }
        }
    };
}
