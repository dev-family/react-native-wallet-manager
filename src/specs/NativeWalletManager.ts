import { TurboModule, TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  canAddPasses(): Promise<boolean>;
  showAddPassControllerFromFile(url: string): Promise<boolean>;
  addPassFromUrl(url: string, headers: Object | null): Promise<boolean>;
  hasPass(
    cardIdentifier: string,
    serialNumber: string | null
  ): Promise<boolean>;
  removePass(
    cardIdentifier: string,
    serialNumber: string | null
  ): Promise<boolean>;
  viewInWallet(
    cardIdentifier: string,
    serialNumber: string | null
  ): Promise<boolean>;
  addPassToGoogleWallet(jwt: string): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeWalletManager');
