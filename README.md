<a href="https://dev.family/?utm_source=github&utm_medium=react-native-wallet-manager&utm_campaign=readme"><img width="auto" center src="https://github.com/dev-family/react-native-wallet-manager/blob/main/docs/logo.png?raw=true" /></a>

# react-native-wallet-manager

This library provides integration with both Apple Wallet on iOS and Google Wallet on Android. It allows you to add, remove, and check for existing passes on iOS, and add passes to Google Wallet on Android.

[![npm version](https://badge.fury.io/js/react-native-wallet-manager.svg)](https://www.npmjs.org/package/react-native-wallet-manager)
[![npm](https://img.shields.io/npm/dt/react-native-wallet-manager.svg)](https://www.npmjs.org/package/react-native-wallet-manager)
[![MIT](https://img.shields.io/dub/l/vibe-d.svg)](https://opensource.org/licenses/MIT)
<br>
[![Platform - Android](https://img.shields.io/badge/platform-Android-3ddc84.svg?style=flat&logo=android)](https://www.android.com)
[![Platform - iOS](https://img.shields.io/badge/platform-iOS-000.svg?style=flat&logo=apple)](https://developer.apple.com/ios)

 <a href="https://x.com/i/flow/login?redirect_after_login=%2Fdev___family">
    <img src="https://img.shields.io/twitter/url/https/twitter.com/bukotsunikki.svg?style=social&label=Follow%20@dev___family" alt="Twitter" />
  </a>

| <img width="230" height="auto" src="https://github.com/dev-family/react-native-wallet-manager/blob/main/docs/ios.gif?raw=true" /> | <img width="230" height="auto" src="https://raw.githubusercontent.com/dev-family/react-native-wallet-manager/refs/heads/main/docs/android.gif?raw=true" /> |
| :-------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------: |
|                                                                iOS                                                                |                                                                          Android                                                                           |

## Installation

```sh
yarn add react-native-wallet-manager
```

or

```sh
npm install react-native-wallet-manager
```

## Setup

### iOS

To enable the Wallet functionality on iOS, you need to add the Wallet capability in Xcode. Follow these steps:

1. Open your project in Xcode (`xcworkspace` file).

2. Select your project **Target**.
3. Go to the **Signing & Capabilities** tab.
4. Click on **+ Capability** to add a new capability.
5. In the search bar, type **Wallet** and add it to your project.

After that, navigate to the `ios` folder in your project directory and run the following command to install necessary dependencies:

```bash
cd ios && pod install
```

### Android

To enable Google Wallet functionality on Android, you need to add the Google Play Services dependency to your project. Follow these steps:

1. Open the `android/app/build.gradle` file in your project.
2. In the `dependencies` section, add the following line with the latest version of `play-services-pay`:

   ```bash
   implementation "com.google.android.gms:play-services-pay:<latest_version>"
   ```

Replace `<latest_version>` with the most recent version number available. You can find the latest version on the [Google Play Services release notes page](https://developers.google.com/android/guides/releases).

## Usage

For platform-specific instructions on how to create passes:

- **iOS**: For a detailed guide on creating Apple Wallet pkpasses visit [this Medium article](https://medium.com/@dev.family/how-to-integrate-apple-wallet-into-the-mobile-app-54700346beb1).
- **Android**: You can find a detailed guide on creating passes for Google Wallet at [this Google Codelab](https://codelabs.developers.google.com/add-to-wallet-web).

To use this library, start by importing it into your React Native component:

```javascript
import WalletManager from 'react-native-wallet-manager';
```

## API

| Method                                                                                                                  | Parameters                                      | iOS | Android |
| ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --- | ------- |
| [`canAddPasses()`](#canaddpasses)                                                                                       | None                                            | ✅  | ✅      |
| [`addPassToGoogleWallet(jwt: string)`](#addpasstogooglewalletjwt-string)                                                | `jwt: string`                                   | ❌  | ✅      |
| [`addPassFromUrl(url: string)`](#addpassfromurlurl-string)                                                              | `url: string`                                   | ✅  | ✅      |
| [`hasPass(cardIdentifier: string, serialNumber?: string)`](#haspasscardidentifier-string-serialnumber-string)           | `cardIdentifier: string, serialNumber?: string` | ✅  | ❌      |
| [`removePass(cardIdentifier: string, serialNumber?: string)`](#removepasscardidentifier-string-serialnumber-string)     | `cardIdentifier: string, serialNumber?: string` | ✅  | ❌      |
| [`viewInWallet(cardIdentifier: string, serialNumber?: string)`](#viewinwalletcardidentifier-string-serialnumber-string) | `cardIdentifier: string, serialNumber?: string` | ✅  | ❌      |
| [`showViewControllerWithData(filePath: string)`](#showviewcontrollerwithdatafilepath-string)                            | `filePath: string`                              | ✅  | ❌      |

### Notes

All methods return a `Promise` that resolves with the result of the operation or rejects if an error occurs.

## canAddPasses()

Checks if the device can add passes to the wallet. This method is supported on both iOS and Android.

### Example

```javascript
const canAddPasses = async () => {
  try {
    const result = await WalletManager.canAddPasses();
    console.log(result);
  } catch (e) {
    console.log(e);
  }
};
```

## addPassToGoogleWallet(jwt: string)

Adds a pass to Google Wallet. This method is only supported on Android.

### Parameters

- `jwt` (string): The JWT token containing the pass information to be added to Google Wallet.

_Note:_ In the example below, you'll see a placeholder for the JWT. You need to generate a valid Google Wallet JWT for testing purposes.

### Example

```javascript
const addPassToGoogleWallet = async () => {
  try {
    await WalletManager.addPassToGoogleWallet(
      'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...'
    );
  } catch (e) {
    console.log(e);
  }
};
```

## addPassFromUrl(url: string)

Adds a pass from a specified URL. This method is supported on both iOS and Android.

- On iOS, it will add the pass to Apple Wallet.
- On Android, it will open the URL in a browser.

### Parameters

- `url` (string): The URL of the pass file (`.pkpass` file) to be added.

### Examples

```javascript
const addPass = async () => {
  try {
    const result = await WalletManager.addPassFromUrl(
      'https://github.com/dev-family/react-native-wallet-manager/blob/main/example/resources/pass.pkpass?raw=true'
    );
    console.log(result);
  } catch (e) {
    console.log(e);
  }
};
```

## hasPass(cardIdentifier: string, serialNumber?: string)

Checks if a pass with a specific identifier exists in the Apple Wallet. This method is only supported on iOS.

### Parameters

- `cardIdentifier` (string): The unique identifier of the pass to check.
- `serialNumber` (string, optional): The serial number of the pass. This parameter is optional and can be used to further specify the pass.

### Example

```javascript
const hasPass = async () => {
  try {
    const result = await WalletManager.hasPass('pass.family.dev.walletManager');
    console.log(`has pass: ${result}`);
  } catch (e) {
    console.log(e, 'hasPass');
  }
};
```

## removePass(cardIdentifier: string, serialNumber?: string)

Removes a pass with a specific identifier from the Apple Wallet. This method is only supported on iOS.

### Parameters

- `cardIdentifier` (string): The unique identifier of the pass to remove.
- `serialNumber` (string, optional): The serial number of the pass. This parameter is optional and can be used to further specify the pass.

### Example

```javascript
const removePass = async () => {
  try {
    const result = await WalletManager.removePass(
      'pass.family.dev.walletManager'
    );
    console.log(`remove pass: ${result}`);
  } catch (e) {
    console.log(e, 'removePass');
  }
};
```

## viewInWallet(cardIdentifier: string, serialNumber?: string)

Opens a pass with a specific identifier in Apple Wallet. This method is only supported on iOS.

### Parameters

- `cardIdentifier` (string): The unique identifier of the pass to view.
- `serialNumber` (string, optional): The serial number of the pass. This parameter is optional and can be used to further specify the pass.

### Example

```javascript
const viewPass = async () => {
  try {
    const result = await WalletManager.viewInWallet(
      'pass.family.dev.walletManager'
    );
    console.log(result);
  } catch (e) {
    console.log(e, 'error Viewing Pass');
  }
};
```

## showViewControllerWithData(filePath: string)

Displays a view controller to add a pass using the data from the specified file path. This method is only supported on iOS.

### Parameters

- `filePath` (string): The path to the `.pkpass` file containing the pass data to be added to Apple Wallet.

### Example

```javascript
const showViewControllerWithData = async (filePath) => {
  try {
    const result = await WalletManager.showViewControllerWithData(filePath);
    console.log(`Pass was added: ${result}`);
  } catch (e) {
    console.error('Error displaying pass view controller:', e);
  }
};
```

Project inspired by [react-native-wallet](https://www.npmjs.com/package/react-native-wallet)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
