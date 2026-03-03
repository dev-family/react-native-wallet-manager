#import <PassKit/PassKit.h>
#import <NativeWalletManagerSpec/NativeWalletManagerSpec.h>
#if __has_include(<react_native_wallet_manager/react_native_wallet_manager-Swift.h>)
// if use_frameworks! :static
#import <react_native_wallet_manager/react_native_wallet_manager-Swift.h>
#else
#import "react_native_wallet_manager-Swift.h"
#endif

@interface NativeWalletManager : NSObject <NativeWalletManagerSpec>
@end

@implementation NativeWalletManager

RCT_EXPORT_MODULE()

WalletManagerImpl *walletManager = [[WalletManagerImpl alloc] init];

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeWalletManagerSpecJSI>(params);
}

- (void)addPassFromUrl:(nonnull NSString *)url headers:(nullable NSDictionary *)headers resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
  [walletManager addPassFromUrl:url headers:headers completion:^(BOOL success, NSString *errorCode, NSString *errorMessage) {
    if (success) {
      resolve(@(YES));
    } else {
      reject(errorCode, errorMessage, nil);
    }
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

