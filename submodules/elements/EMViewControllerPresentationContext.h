#import <Foundation/Foundation.h>

@class EMViewController;

@protocol EMViewControllerPresentationContext <NSObject>

- (void)presentController:(EMViewController *)controller;

@end
