package com.reactnativewalletmanager;

import android.app.Activity;
import android.content.Intent;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.google.android.gms.pay.PayClient;
import com.google.android.gms.pay.Pay;
import com.google.android.gms.pay.PayApiAvailabilityStatus;

class WalletManagerModule(reactContext: ReactApplicationContext) : NativeWalletManagerSpec(reactContext) {

    private val walletClient: PayClient = Pay.getClient(reactContext)
    private var addPassPromise: Promise? = null
    private val ADD_TO_GOOGLE_WALLET_REQUEST_CODE = 1001

    companion object {
      const val NAME = "NativeWalletManager"
    }

  override fun getName() = NAME

  private val mActivityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
      if (requestCode == ADD_TO_GOOGLE_WALLET_REQUEST_CODE) {
        addPassPromise?.let { promise ->
          when (resultCode) {
            Activity.RESULT_OK -> promise.resolve("Pass successfully added to Google Wallet")
            Activity.RESULT_CANCELED -> promise.reject("RESULT_CANCELED", "The operation was canceled by the user.")
            else -> {
              val error = data?.getStringExtra("error") ?: "Unknown error"
              promise.reject("UNKNOWN_ERROR", "An error occurred: $error")
            }
          }
          addPassPromise = null
        }
      }
    }
  }

    init {
        reactContext.addActivityEventListener(mActivityEventListener)
    }

    override fun canAddPasses(promise: Promise) {
        walletClient.getPayApiAvailabilityStatus(PayClient.RequestType.SAVE_PASSES)
            .addOnSuccessListener { status ->
                promise.resolve(status == PayApiAvailabilityStatus.AVAILABLE)
            }
            .addOnFailureListener { e ->
                promise.reject(
                    "ERROR",
                    "Error when checking the availability of the Google Wallet API: ${e.message}",
                    e
                )
            }
    }

    override fun addPassToGoogleWallet(jwt: String, promise: Promise) {
        val activity = currentActivity
        if (activity != null) {
            addPassPromise = promise
            try {
                walletClient.savePassesJwt(jwt, activity, ADD_TO_GOOGLE_WALLET_REQUEST_CODE)
            } catch (e: Exception) {
                e.printStackTrace()
                when (e) {
                    is com.google.android.gms.common.api.ApiException -> {
                        val statusCode = e.statusCode
                        val statusMessage = com.google.android.gms.common.api.CommonStatusCodes.getStatusCodeString(statusCode)
                        promise.reject(
                            "API_ERROR",
                            "Google Pay API error occurred. Status code: $statusCode, Message: $statusMessage"
                        )
                    }
                    else -> {
                        promise.reject(
                            "GENERAL_ERROR",
                            "Error when saving to Google Wallet: ${e.message}",
                            e
                        )
                    }
                }
                addPassPromise = null
            }
        } else {
            promise.reject("NO_ACTIVITY", "Current activity is unavailable.")
        }
    }

  override fun showAddPassControllerFromFile(url: String, promise: Promise) {
    promise.reject("UNSUPPORTED_PLATFORM", "This function is not supported on Android.")
  }

  override fun addPassFromUrl(url: String, promise: Promise) {
    promise.reject("UNSUPPORTED_PLATFORM", "This function is not supported on Android.")
  }

  override fun hasPass(cardIdentifier: String, serialNumber: String?, promise: Promise) {
    promise.reject("UNSUPPORTED_PLATFORM", "This function is not supported on Android.")
  }

  override fun removePass(cardIdentifier: String, serialNumber: String?, promise: Promise) {
    promise.reject("UNSUPPORTED_PLATFORM", "This function is not supported on Android.")
  }

  override fun viewInWallet(cardIdentifier: String, serialNumber: String?, promise: Promise) {
    promise.reject("UNSUPPORTED_PLATFORM", "This function is not supported on Android.")
  }
}
