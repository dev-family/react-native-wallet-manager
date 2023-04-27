<a href="https://dev.family/?utm_source=github&utm_medium=react-native-wallet-manager&utm_campaign=readme"><img width="auto" center src="https://github.com/dev-family/react-native-wallet-manager/blob/main/docs/logo.png?raw=true" /></a>

# react-native-wallet-manager

Provides some Apple Wallet's functionality, like adding passes, removing passes and checking passises for existing.

[![npm version](https://badge.fury.io/js/react-native-wallet-manager.svg)](https://www.npmjs.org/package/react-native-wallet-manager)
[![npm](https://img.shields.io/npm/dt/react-native-wallet-manager.svg)](https://www.npmjs.org/package/react-native-wallet-manager)
[![MIT](https://img.shields.io/dub/l/vibe-d.svg)](https://opensource.org/licenses/MIT)
<br>
[![Platform - Android](https://img.shields.io/badge/platform-Android-3ddc84.svg?style=flat&logo=android)](https://www.android.com)
[![Platform - iOS](https://img.shields.io/badge/platform-iOS-000.svg?style=flat&logo=apple)](https://developer.apple.com/ios)

💜[FOLLOW FOR RECENT NEWS](https://twitter.com/dev___family)💜

<img width="400" height="auto" center src="https://github.com/dev-family/react-native-wallet-manager/blob/main/docs/screenshot.gif?raw=true" />

## Installation

```sh
yarn add react-native-wallet-manager
```

or

```sh
npm install react-native-wallet-manager
```

## iOS installation

Add Wallet module to capabilities in Xcode.

_Don't forget to run `pod install`!_

## Usage

### Adding pass to wallet by url

```js
import WalletManager from 'react-native-wallet-manager';

// ...

try {
  const result = await WalletManager.addPassFromUrl(
    'https://github.com/dev-family/react-native-wallet-manager/blob/main/example/resources/test.pkpass?raw=true'
  );
  console.log(result);
  // true
} catch (e) {
  console.log(e);
}
```

### Checking for pass exists (iOS only)

```js
try {
  const result = await WalletManager.hasPass(
    'pass.family.dev.stage.beerpoint-master',
    'serial-xxx'
  );
  console.log(result);
} catch (e) {
  console.log(e);
}
```

First argument is pass identifier. You can pass second argument (optional) to specify pass serial number.

### Removing pass (iOS only)

```js
try {
  const result = await WalletManager.removePass(
    'pass.family.dev.stage.beerpoint-master',
    'serial-xxx'
  );
  console.log(result);
} catch (e) {
  console.log(e);
}
```

First argument is pass identifier. You can pass second argument (optional) to specify pass serial number.

Project inspired by [react-native-wallet](https://www.npmjs.com/package/react-native-wallet)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
