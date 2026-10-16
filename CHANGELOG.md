# Changelog

## v0.0.2

### Added

- Added a method that allows user to view the added Pass into the wallet ([c4e7dabb5aebf1f7176cf3815436156648025ffa](https://github.com/dev-family/react-native-wallet-manager/pull/1/commits/c4e7dabb5aebf1f7176cf3815436156648025ffa) by [@pratikkishornaik](https://github.com/pratikkishornaik))

## v0.0.3

### Added

- Add suport for new versions of RN on android side. ([17bc045ae5b37e1d142bc94ffa7e5693973730c9](https://github.com/dev-family/react-native-wallet-manager/pull/11/commits/17bc045ae5b37e1d142bc94ffa7e5693973730c9) by [@LucasVeloz](https://github.com/LucasVeloz))

## v0.0.4

### Added

- Adds ability to check for iOS PKAddPassesViewController canAddPasses method. ([1b8c5c4f79a34820f6e3a709240f26b3e247b53f](https://github.com/dev-family/react-native-wallet-manager/pull/11/commits/1b8c5c4f79a34820f6e3a709240f26b3e247b53f) by [@brantleyenglish](https://github.com/brantleyenglish))

## v0.0.5

### Added

- Added support to android target SDK v 33. ([6470e80ebae77019cb29c4213a60deb9b7bfb06c](https://github.com/dev-family/react-native-wallet-manager/pull/15/commits/6470e80ebae77019cb29c4213a60deb9b7bfb06c) by [@ferencik-f](https://github.com/ferencik-f))

## v0.0.6

### Added

- Added support for React Native 0.73 on android. ([86776d5fa9d3ef9ccccb98db6387d3e361471ae6](https://github.com/dev-family/react-native-wallet-manager/pull/18/commits/86776d5fa9d3ef9ccccb98db6387d3e361471ae6) by [@LucasVeloz](https://github.com/LucasVeloz))

## v0.0.7

### Added

- Added showAddPassControllerFromFile method for iOS platform to pass in local filepath of .pkpass. ([f989b785d8e54f4642dba74226850b9d24b10508](https://github.com/dev-family/react-native-wallet-manager/pull/21/commits/f989b785d8e54f4642dba74226850b9d24b10508) by [@devt259](https://github.com/devt259))

## v1.1.0

### Added

- **Google Wallet**: added new methods for Android:
  - **addPassToGoogleWallet** method to add passes to Google Wallet.
  - **canAddPasses** method to verify if Google Wallet is supported on the device.

### Updated

- **Documentation**: completely revamped for improved usability and structure.
  - Detailed sections added for using the new Google Wallet methods.
  - Improved navigation and added step-by-step examples.

### Fixed

- **Examples**: updated code examples for all new features, including integration with Google Wallet on Android.

## v1.1.1

### Fixed

- Replaced **dispatch_get_main_queue** with **dispatch_get_global_queue** in methods **addPassFromUrl** and **showAddPassControllerFromFile** to fix the app crashed, if Wallet not installed. ([e4766ca091e09b1234c027640c04f34e0307bd17](https://github.com/dev-family/react-native-wallet-manager/pull/30/commits/e4766ca091e09b1234c027640c04f34e0307bd17) by [@ghorbani-m](https://github.com/ghorbani-m))

## v1.1.2

### Chore

- Replace jcenter() with mavenCentral() in build.gradle. ([7be0bc45f6d872aa2ebd2d43d678340e5200181f](https://github.com/dev-family/react-native-wallet-manager/pull/39/commits/7be0bc45f6d872aa2ebd2d43d678340e5200181f) by [@vnahornyi](https://github.com/vnahornyi))

## v1.1.3

### Fixes

- Build: ensure lib output is included in published package

## v2.0.0

### Added

- feat: add support for the new architecture (TurboModule/Fabric)

## v2.0.1

### Fixed

- swift class not found if using static frameworks

## v2.2.0

### Added

- iOS: `addPassFromUrl` and `showAddPassControllerFromFile` accept `.pkpasses` bundles (ZIP or ZIP64, stored or deflated) and present every pass in one sheet. Passes already in Wallet are left out, `PASS_ALREADY_EXISTS` is returned only when every pass of the bundle is already there. Fixes [#44](https://github.com/dev-family/react-native-wallet-manager/issues/44), refs [#38](https://github.com/dev-family/react-native-wallet-manager/issues/38)
- iOS: `addPassesFromUrls(urls, headers?)` downloads several `.pkpass` files or `.pkpasses` bundles and presents all passes in one sheet. Fixes [#38](https://github.com/dev-family/react-native-wallet-manager/issues/38)
- iOS, Android: `ADD_PASS_IN_PROGRESS` error code, also added to the `WalletErrorCode` type

### Fixed

- Android: skip the explicit Kotlin plugin when AGP already registers the kotlin extension, fixes the build on AGP 9 (Expo SDK 58, RN 0.87). ([3ecff64c06bb680876b5a38314346aec5a7d6fad](https://github.com/dev-family/react-native-wallet-manager/pull/46/commits/3ecff64c06bb680876b5a38314346aec5a7d6fad) by [@gabrieldonadel](https://github.com/gabrieldonadel))
- Android: read the current activity from the application context, the bare `currentActivity` access no longer compiles on Kotlin 2.2 (RN 0.87), fixes [#47](https://github.com/dev-family/react-native-wallet-manager/issues/47). ([0f60e18f5f52ad7d77244424b3c4daed5773d558](https://github.com/dev-family/react-native-wallet-manager/pull/45/commits/0f60e18f5f52ad7d77244424b3c4daed5773d558) by [@aattola](https://github.com/aattola))
- iOS, Android: only one pass is added at a time. While a pass is being added, `addPassFromUrl`, `addPassesFromUrls` and `addPassToGoogleWallet` reject with `ADD_PASS_IN_PROGRESS` and `showAddPassControllerFromFile` resolves with `false`. Before, a second call replaced the pending request and the first promise never settled
- iOS: if the Apple Wallet sheet cannot be shown, the pending promise rejects with `CONTROLLER_ERROR` on the next call instead of never settling
- iOS: run the module on the main thread, PassKit sheets were presented from a background queue
- iOS: `addPassFromUrl` rejects a URL without a scheme with `INVALID_URL` and percent-encodes invalid characters on every iOS version. Before, iOS 16 and earlier rejected such URLs with `INVALID_URL`, iOS 17 and later with `NETWORK_ERROR`
- Without the New Architecture, importing the library no longer crashes the app. Method calls reject with an error that says the New Architecture is required and points to 1.1.3, the README explains how to enable it. Refs [#43](https://github.com/dev-family/react-native-wallet-manager/issues/43)
- iOS: `addPassFromUrl` no longer crashes when a header value is not a string. A number or boolean is sent as text, `null` is skipped
- Android: `addPassFromUrl` sends a number or boolean header value as text and skips `null`. Before, such a value rejected with `NETWORK_ERROR`
- iOS: a pass is always downloaded again, a cached response for the same URL is never used. Before, a cached response could be reused and an updated pass was not downloaded
- Package: ship `react-native.config.js`, exclude `android/.gradle` and drop the Gradle wrapper from the npm tarball

### Chore

- Example: add Gemfile and refresh Podfile.lock, log the `addPassToGoogleWallet` result
- Example: add a `.pkpasses` bundle button
- README: document the real `showAddPassControllerFromFile` name, the `headers` parameter of `addPassFromUrl`, error codes for both platforms, return values, pass visibility on iOS and how to enable the New Architecture; drop the manual `play-services-pay` setup step
- Ignore `example/android/app/.cxx`
