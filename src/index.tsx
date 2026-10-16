import { Platform } from 'react-native';
import NativeWalletManager from './specs/NativeWalletManager';

/**
 * Error codes of the promises returned by addPassFromUrl, addPassesFromUrls
 * and addPassToGoogleWallet
 */
export type WalletErrorCode =
  // Shared error codes
  | 'INVALID_URL'
  | 'NETWORK_ERROR'
  | 'HTTP_ERROR'
  | 'USER_CANCELLED'
  | 'ADD_PASS_IN_PROGRESS'
  // iOS-specific error codes
  | 'INVALID_DATA'
  | 'INVALID_PASS'
  | 'PASS_ALREADY_EXISTS'
  | 'NO_VIEW_CONTROLLER'
  | 'CONTROLLER_ERROR'
  // Android-specific error codes
  | 'NO_ACTIVITY'
  | 'API_ERROR'
  | 'GENERAL_ERROR';

/**
 * Error object thrown when addPassFromUrl, addPassesFromUrls or
 * addPassToGoogleWallet fails
 */
export type WalletError = Error & {
  code: WalletErrorCode;
};

const getNativeModule = () => {
  if (NativeWalletManager == null) {
    throw new Error(
      'react-native-wallet-manager: native module NativeWalletManager not found. ' +
        'Version 2.x requires the New Architecture (TurboModules); for the old architecture use 1.1.3. ' +
        'Rebuild the app after installing (run pod install on iOS).'
    );
  }
  return NativeWalletManager;
};

export default {
  canAddPasses: async () => {
    return await getNativeModule().canAddPasses();
  },
  showAddPassControllerFromFile: async (filePath: string) => {
    if (Platform.OS === 'android') {
      throw new Error(
        'showAddPassControllerFromFile method not available on Android'
      );
    }
    return getNativeModule().showAddPassControllerFromFile(filePath);
  },
  addPassToGoogleWallet: async (jwt: string) => {
    if (Platform.OS === 'ios') {
      throw new Error('addPassToGoogleWallet method not available on IOS');
    }
    return await getNativeModule().addPassToGoogleWallet(jwt);
  },
  addPassFromUrl: async (url: string, headers?: Record<string, string>) => {
    return await getNativeModule().addPassFromUrl(url, headers ?? null);
  },
  addPassesFromUrls: async (
    urls: ReadonlyArray<string>,
    headers?: Record<string, string>
  ) => {
    if (Platform.OS === 'android') {
      throw new Error('addPassesFromUrls method not available on Android');
    }
    return await getNativeModule().addPassesFromUrls(urls, headers ?? null);
  },
  hasPass: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('hasPass method not available on Android');
    }
    return await getNativeModule().hasPass(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
  removePass: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('removePass method not available on Android');
    }
    return await getNativeModule().removePass(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
  viewInWallet: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('viewInWallet method not available on Android');
    }
    return await getNativeModule().viewInWallet(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
};
