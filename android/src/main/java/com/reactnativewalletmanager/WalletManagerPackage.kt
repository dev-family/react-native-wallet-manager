package com.reactnativewalletmanager;

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class WalletManagerPackage : BaseReactPackage() {

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? =
    (if (name == WalletManagerModule.NAME) {
      WalletManagerModule(reactContext)
    } else {
      null
    }) as NativeModule?

  override fun getReactModuleInfoProvider() = ReactModuleInfoProvider {
    mapOf(
      WalletManagerModule.NAME to ReactModuleInfo(
        name = WalletManagerModule.NAME,
        className = WalletManagerModule.NAME,
        canOverrideExistingModule = false,
        needsEagerInit = false,
        isCxxModule = false,
        isTurboModule = true,
        hasConstants = false
      )
    )
  }
}

