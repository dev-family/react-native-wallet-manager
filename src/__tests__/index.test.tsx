const mockPlatform = { OS: 'ios' };
const mockNativeModule = {
  addPassesFromUrls: jest.fn(async () => true),
};
let mockGetNativeModule: () => typeof mockNativeModule | null = () =>
  mockNativeModule;

jest.mock('react-native', () => ({
  Platform: mockPlatform,
  TurboModuleRegistry: { get: jest.fn(() => mockGetNativeModule()) },
}));

const loadWalletManager = () => {
  jest.resetModules();
  return require('../index').default;
};

beforeEach(() => {
  mockPlatform.OS = 'ios';
});

describe('without the native module', () => {
  beforeEach(() => {
    mockGetNativeModule = () => null;
  });

  it('can be imported', () => {
    expect(loadWalletManager).not.toThrow();
  });

  it('rejects method calls with a descriptive error', async () => {
    const WalletManager = loadWalletManager();
    await expect(WalletManager.canAddPasses()).rejects.toThrow(
      'requires the New Architecture'
    );
    await expect(
      WalletManager.addPassFromUrl('https://example.com/pass.pkpass')
    ).rejects.toThrow('native module NativeWalletManager not found');
  });
});

describe('with the native module', () => {
  const nativeModule = {
    addPassFromUrl: jest.fn(async () => true),
    hasPass: jest.fn(async () => true),
  };

  beforeEach(() => {
    mockGetNativeModule = () => nativeModule as any;
  });

  it('passes null headers to addPassFromUrl when they are omitted', async () => {
    const WalletManager = loadWalletManager();
    await WalletManager.addPassFromUrl('https://example.com/a.pkpass');
    expect(nativeModule.addPassFromUrl).toHaveBeenCalledWith(
      'https://example.com/a.pkpass',
      null
    );
  });

  it('rejects iOS-only methods on android without calling native code', async () => {
    mockPlatform.OS = 'android';
    const WalletManager = loadWalletManager();
    for (const call of [
      () => WalletManager.hasPass('id'),
      () => WalletManager.removePass('id'),
      () => WalletManager.viewInWallet('id'),
      () => WalletManager.showAddPassControllerFromFile('/x'),
    ]) {
      await expect(call()).rejects.toThrow('not available on Android');
    }
    expect(nativeModule.hasPass).not.toHaveBeenCalled();
  });

  it('rejects addPassToGoogleWallet on ios', async () => {
    const WalletManager = loadWalletManager();
    await expect(WalletManager.addPassToGoogleWallet('jwt')).rejects.toThrow(
      'addPassToGoogleWallet method not available on IOS'
    );
  });
});

describe('addPassesFromUrls', () => {
  beforeEach(() => {
    mockGetNativeModule = () => mockNativeModule;
    mockNativeModule.addPassesFromUrls.mockClear();
  });

  it('passes the urls and null headers to the native module on ios', async () => {
    const WalletManager = loadWalletManager();
    const urls = [
      'https://example.com/a.pkpass',
      'https://example.com/b.pkpass',
    ];
    await expect(WalletManager.addPassesFromUrls(urls)).resolves.toBe(true);
    expect(mockNativeModule.addPassesFromUrls).toHaveBeenCalledWith(urls, null);
  });

  it('passes the headers to the native module', async () => {
    const WalletManager = loadWalletManager();
    const urls = ['https://example.com/a.pkpass'] as const;
    const headers = { Authorization: 'Bearer token' };
    await WalletManager.addPassesFromUrls(urls, headers);
    expect(mockNativeModule.addPassesFromUrls).toHaveBeenCalledWith(
      urls,
      headers
    );
  });

  it('is not available on android', async () => {
    mockPlatform.OS = 'android';
    const WalletManager = loadWalletManager();
    await expect(WalletManager.addPassesFromUrls([])).rejects.toThrow(
      'addPassesFromUrls method not available on Android'
    );
    expect(mockNativeModule.addPassesFromUrls).not.toHaveBeenCalled();
  });
});
