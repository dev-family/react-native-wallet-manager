#import <PassKit/PassKit.h>
#import <NativeWalletManagerSpec/NativeWalletManagerSpec.h>
@interface NativeWalletManager : NSObject <NativeWalletManagerSpec>
@end

#import "react_native_wallet_manager-Swift.h"

@implementation NativeWalletManager

RCT_EXPORT_MODULE()

WalletManagerImpl *walletManager = [[WalletManagerImpl alloc] init];

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeWalletManagerSpecJSI>(params);
}

- (void)addPassFromUrl:(nonnull NSString *)url resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
  [walletManager addPassFromUrl:url completion:^(BOOL added) {
         resolve(@(added));
     }];
}

- (void)addPassToGoogleWallet:(nonnull NSString *)jwt resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
  
}

- (void)canAddPasses:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject { 
  BOOL result = [walletManager canAddPasses];
  if (result) {
          resolve(@(YES));
      } else {
          resolve(@(NO));
      }
}

- (void)hasPass:(nonnull NSString *)cardIdentifier serialNumber:(NSString * _Nullable)serialNumber resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject { 
  BOOL result = [walletManager hasPass:cardIdentifier serialNumber:serialNumber];
  if (result) {
          resolve(@(YES));
      } else {
          resolve(@(NO));
      }
}

- (void)removePass:(nonnull NSString *)cardIdentifier serialNumber:(NSString * _Nullable)serialNumber resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject { 
  BOOL result = [walletManager removePass:cardIdentifier serialNumber:serialNumber];
  if (result) {
          resolve(@(YES));
      } else {
          resolve(@(NO));
      }
}

- (void)showAddPassControllerFromFile:(nonnull NSString *)url resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject { 
  BOOL result = [walletManager showAddPassControllerFromFile: url];
  if (result) {
          resolve(@(YES));
      } else {
          resolve(@(NO));
      }
}

- (void)viewInWallet:(nonnull NSString *)cardIdentifier serialNumber:(NSString * _Nullable)serialNumber resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject { 
  BOOL result = [walletManager viewInWallet:cardIdentifier serialNumber:serialNumber];
  if (result) {
          resolve(@(YES));
      } else {
          resolve(@(NO));
      }
}

@end

