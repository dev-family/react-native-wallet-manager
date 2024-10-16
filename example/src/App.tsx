import * as React from 'react';
import {
  StyleSheet,
  View,
  SafeAreaView,
  StatusBar,
  Button,
  Platform,
} from 'react-native';
import WalletManager from 'react-native-wallet-manager';
import WalletButton from './WalletButton';

export default function App() {
  const addPassToGoogleWallet = async () => {
    try {
      await WalletManager.addPassToGoogleWallet(
        'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ3YWxsZXQtbWFuYWdlci1zZXJ2aWNlQHdhbGxldG1hbmFnZXJleGFtcGxlLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwiYXVkIjoiZ29vZ2xlIiwib3JpZ2lucyI6W10sInR5cCI6InNhdmV0b3dhbGxldCIsInBheWxvYWQiOnsiZ2VuZXJpY09iamVjdHMiOlt7ImlkIjoiMzM4ODAwMDAwMDAyMjc4Njk5NC5tc2hiX2JjIiwiY2xhc3NJZCI6IjMzODgwMDAwMDAwMjI3ODY5OTQuY29kZWxhYl9jbGFzcyIsImdlbmVyaWNUeXBlIjoiR0VORVJJQ19UWVBFX1VOU1BFQ0lGSUVEIiwiaGV4QmFja2dyb3VuZENvbG9yIjoiIzM2MUNBNSIsImxvZ28iOnsic291cmNlVXJpIjp7InVyaSI6Imh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9kZXYtZmFtaWx5L3JlYWN0LW5hdGl2ZS13YWxsZXQtbWFuYWdlci9yZWZzL2hlYWRzL21haW4vZG9jcy9sb2dvQW5kcm9pZC5wbmcifX0sImNhcmRUaXRsZSI6eyJkZWZhdWx0VmFsdWUiOnsibGFuZ3VhZ2UiOiJlbiIsInZhbHVlIjoiRGV2LkZhbWlseSJ9fSwic3ViaGVhZGVyIjp7ImRlZmF1bHRWYWx1ZSI6eyJsYW5ndWFnZSI6ImVuIiwidmFsdWUiOiJBdHRlbmRlZSJ9fSwiaGVhZGVyIjp7ImRlZmF1bHRWYWx1ZSI6eyJsYW5ndWFnZSI6ImVuIiwidmFsdWUiOiJNYXJpYSJ9fSwiYmFyY29kZSI6eyJ0eXBlIjoiUVJfQ09ERSIsInZhbHVlIjoiaHR0cHM6Ly9kZXYuZmFtaWx5In0sImhlcm9JbWFnZSI6eyJzb3VyY2VVcmkiOnsidXJpIjoiaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2Rldi1mYW1pbHkvcmVhY3QtbmF0aXZlLXdhbGxldC1tYW5hZ2VyL3JlZnMvaGVhZHMvbWFpbi9kb2NzL3N0cmlwZS5wbmcifX0sInRleHRNb2R1bGVzRGF0YSI6W3siaGVhZGVyIjoiUE9JTlRTIiwiYm9keSI6IjEyMzQiLCJpZCI6InBvaW50cyJ9LHsiaGVhZGVyIjoiQ09OVEFDVFMiLCJib2R5IjoiMjAiLCJpZCI6ImNvbnRhY3RzIn1dfV19LCJpYXQiOjE3MjkwMDMwMDV9.jIBtnHEz6HGqhRwoNCPiq3oGAdAZV6fct9tfC7BxozRQNJtJQGK423l-g6tIK6k9XcedPSvoi5467I4OAfjXR4F2yu5xc-Ry-xMkNeLut1hNgHRd0g-L4moDrk3pSBiuP7k32IS5eouZ8bX_7VcklSLMV98YvD17HI0SCCaUjxv3i7CaGRFsJTM-45BAffp-10nqkL5LsrGt6Sk8a12UdqI7WRav0xzOvkyA2ieQYX1URWeoGS_F54-943LrBpa9AKoZK3ScdTz0K3Ts2VssjmXraV_8Ns3l70fyPzQejaTFTJ1TYpUBdr1cWfeduQUCJGZPYmotfqZ38rWZty1cBg'
      );
    } catch (e) {
      console.log(e);
    }
  };

  const canAddPasses = async () => {
    try {
      const result = await WalletManager.canAddPasses();
      console.log(result);
    } catch (e) {
      console.log(e);
    }
  };

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

  const hasPass = async () => {
    try {
      const result = await WalletManager.hasPass(
        'pass.family.dev.walletManager'
      );
      console.log(`has pass: ${result}`);
    } catch (e) {
      console.log(e, 'hasPass');
    }
  };

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

  return (
    <SafeAreaView style={styles.wrapper}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.container}>
        <WalletButton
          onPress={Platform.OS === 'ios' ? addPass : addPassToGoogleWallet}
        />
        <Button onPress={canAddPasses} title="Can add passes" />
        {Platform.OS === 'ios' && (
          <>
            <Button onPress={removePass} title="Remove pass" />
            <Button onPress={hasPass} title="Has pass" />
            <Button onPress={viewPass} title="View pass" />
          </>
        )}
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
