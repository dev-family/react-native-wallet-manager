import * as React from 'react';
import {
  StyleSheet,
  View,
  SafeAreaView,
  StatusBar,
  Button,
} from 'react-native';
import WalletManager from 'react-native-wallet-manager';
import WalletButton from './WalletButton';

export default function App() {
  const addPass = async () => {
    try {
      const result = await WalletManager.addPassFromUrl(
        'https://github.com/dev-family/react-native-wallet-manager/blob/main/example/resources/test.pkpass?raw=true'
      );
      console.log(result);
    } catch (e) {
      console.log(e);
    }
  };

  const removePass = async () => {
    try {
      const result = await WalletManager.removePass(
        'pass.family.dev.stage.beerpoint-master'
      );
      alert(`remove pass: ${result}`);
    } catch (e) {
      console.log(e, 'removePass');
    }
  };

  const hasPass = async () => {
    try {
      const result = await WalletManager.hasPass(
        'pass.family.dev.stage.beerpoint-master'
      );
      alert(`has pass: ${result}`);
    } catch (e) {
      console.log(e, 'hasPass');
    }
  };

  const viewPass = async () => {
    try {
      await WalletManager.viewInWallet(
        'pass.family.dev.stage.beerpoint-master'
      );
    } catch (e) {
      console.log(e, 'error Viewing Pass');
    }
  };

  return (
    <SafeAreaView style={styles.wrapper}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.container}>
        <WalletButton onPress={addPass} />
        <Button onPress={removePass} title="Remove pass" />
        <Button onPress={hasPass} title="Has pass" />
        <Button onPress={viewPass} title="View pass" />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    flex: 1,
  },
  container: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
