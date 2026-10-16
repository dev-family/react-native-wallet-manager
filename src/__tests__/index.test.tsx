jest.mock('react-native', () => ({
  Platform: { OS: 'ios' },
  TurboModuleRegistry: { get: jest.fn(() => null) },
}));

describe('without the native module', () => {
  it('can be imported', () => {
    expect(() => require('../index')).not.toThrow();
  });

  it('rejects method calls with a descriptive error', async () => {
    const WalletManager = require('../index').default;
    await expect(WalletManager.canAddPasses()).rejects.toThrow(
      'requires the New Architecture'
    );
    await expect(
      WalletManager.addPassFromUrl('https://example.com/pass.pkpass')
    ).rejects.toThrow('native module NativeWalletManager not found');
  });
});
