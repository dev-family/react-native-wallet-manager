import { Platform } from 'react-native';
import WalletManager from './specs/NativeWalletManager';

/**
 * Error codes that can be thrown by addPassFromUrl
 */
export type WalletErrorCode =
  // Shared error codes
  | 'INVALID_URL'
  | 'NETWORK_ERROR'
  | 'HTTP_ERROR'
  | 'USER_CANCELLED'
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
 * Error object thrown when addPassFromUrl fails
 */
export type WalletError = Error & {
  code: WalletErrorCode;
};

export default {
  canAddPasses: async () => {
    return await WalletManager.canAddPasses();
  },
  showAddPassControllerFromFile: async (filePath: string) => {
    if (Platform.OS === 'android') {
      throw new Error(
        'showAddPassControllerFromFile method not available on Android'
      );
    }
    return WalletManager.showAddPassControllerFromFile(filePath);
  },
  addPassToGoogleWallet: async (jwt: string) => {
    if (Platform.OS === 'ios') {
      throw new Error('addPassToGoogleWallet method not available on IOS');
    }
    return await WalletManager.addPassToGoogleWallet(jwt);
  },
  addPassFromUrl: (url: string, headers?: Record<string, string>) =>
    WalletManager.addPassFromUrl(url, headers ?? null),
  hasPass: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('hasPass method not available on Android');
    }
    return await WalletManager.hasPass(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
  removePass: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('removePass method not available on Android');
    }
    return await WalletManager.removePass(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
  viewInWallet: async (cardIdentifier: string, serialNumber?: string) => {
    if (Platform.OS === 'android') {
      throw new Error('viewInWallet method not available on Android');
    }
    return await WalletManager.viewInWallet(
      cardIdentifier,
      serialNumber != null ? serialNumber : null
    );
  },
};
