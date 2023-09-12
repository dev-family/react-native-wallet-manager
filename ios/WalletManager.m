// RCTCalendarModule.m
#import "WalletManager.h"
#import <PassKit/PassKit.h>

static NSString *const rejectCode = @"wallet";

@interface WalletManager () <PKAddPassesViewControllerDelegate>

@property (nonatomic, copy) RCTPromiseResolveBlock resolveBlock;
@property (nonatomic, strong) PKPass *pass;
@property (nonatomic, strong) PKPassLibrary *passLibrary;

@end

@implementation WalletManager

RCT_EXPORT_MODULE(WalletManager);

RCT_EXPORT_METHOD(
                  canAddPasses:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  BOOL showPass = [PKAddPassesViewController canAddPasses];
  if (showPass) {
    resolve(@(YES));
    return;
  }
  resolve(@(NO));
  return;
}

RCT_EXPORT_METHOD(
                  addPassFromUrl:(NSString *)pass
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  ) {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSURL *passURL = [[NSURL alloc] initWithString:pass];
    if (!passURL) {
      reject(rejectCode, @"The pass URL is invalid", nil);
      return;
    }
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:passURL];
    if (!data) {
      reject(rejectCode, @"The pass data is invalid", nil);
      return;
    }
    
    [self showViewControllerWithData:data resolver:resolve rejecter:reject];
  });
}

RCT_EXPORT_METHOD(
                  hasPass:(NSString *)cardIdentifier
                  serialNumber:(nullable NSString *)cardSerialNumber
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  PKPassLibrary * passLibrary = [[PKPassLibrary alloc] init];
  NSArray *passes = [passLibrary passes];
  
  for (PKPass *pass in passes) {
    if ([self checkPassByIdentifier:pass identifier:cardIdentifier serialNumber:cardSerialNumber]) {
      resolve(@(YES));
      return;
    }
  }
  
  resolve(@(NO));
  return;
}

RCT_EXPORT_METHOD(
                  removePass:(NSString *)cardIdentifier
                  serialNumber:(nullable NSString *)cardSerialNumber
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  PKPassLibrary *passLibrary = [[PKPassLibrary alloc] init];
  NSArray *passes = [passLibrary passes];
  
  BOOL result = FALSE;
  
  for (PKPass *pass in passes) {
    if ([self checkPassByIdentifier:pass identifier:cardIdentifier serialNumber:cardSerialNumber]) {
      [passLibrary removePass:pass];
      result = TRUE;
    }
  }
  
  if (result == TRUE) {
    resolve(@(YES));
  } else {
    resolve(@(NO));
  }
  return;
}


RCT_EXPORT_METHOD(
                  viewInWallet:(NSString *)cardIdentifier
                  serialNumber:(nullable NSString *)cardSerialNumber
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  PKPassLibrary * passLibrary = [[PKPassLibrary alloc] init];
  NSArray *passes = [passLibrary passes];
  
  for (PKPass *pass in passes) {
    if ([self checkPassByIdentifier:pass identifier:cardIdentifier serialNumber:cardSerialNumber]) {
        if(pass.passURL){
            [[UIApplication sharedApplication] openURL: pass.passURL options:@{} completionHandler:nil];
        }
      resolve(@(YES));
      return;
    }
  }
  
  resolve(@(NO));
  return;
}




- (void)showViewControllerWithData:(NSData *)data
                          resolver:(RCTPromiseResolveBlock)resolve
                          rejecter:(RCTPromiseRejectBlock)reject {
  NSError *passError;
  self.pass = [[PKPass alloc] initWithData:data error:&passError];
  
  if (passError) {
    reject(rejectCode, @"The pass is invalid", passError);
    return;
  }
  
  self.passLibrary = [[PKPassLibrary alloc] init];
  if ([self.passLibrary containsPass:self.pass]) {
    resolve(@(YES));
    return;
  }
  
  UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  
  PKAddPassesViewController *passController = [[PKAddPassesViewController alloc] initWithPass:self.pass];
  passController.delegate = self;
  self.resolveBlock = resolve;
  
  while (viewController.presentedViewController) {
    viewController = viewController.presentedViewController;
  }
  
  [viewController presentViewController:passController animated:YES completion:nil];
}

#pragma mark - PKAddPassesViewControllerDelegate

- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller
{
  [controller dismissViewControllerAnimated:YES completion:^{
    if (self.resolveBlock) {
      self.resolveBlock(@([self.passLibrary containsPass:self.pass]));
      self.resolveBlock = nil;
    }
    
    controller.delegate = nil;
    self.passLibrary = nil;
    self.pass = nil;
  }];
}

- (BOOL)checkPassByIdentifier:(PKPass *)pass
                   identifier:(NSString *)cardIdentifier
                 serialNumber:(nullable NSString *)cardSerialNumber
{
  NSString *passTypeIdentifier = [pass passTypeIdentifier];
  if([passTypeIdentifier isEqualToString:cardIdentifier] == FALSE) {
    return FALSE;
  }
  if (cardSerialNumber) {
    NSString *serialNumber = [pass serialNumber];
    if([serialNumber isEqualToString:cardSerialNumber] == FALSE) {
      return FALSE;
    }
  }
  
  return TRUE;
}

@end
