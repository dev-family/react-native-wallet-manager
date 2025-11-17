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
