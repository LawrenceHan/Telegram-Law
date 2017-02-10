#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Elements/EMViewControllerPresentationContext.h>

@interface EMUserInterface : NSObject

- (void)activate;

- (id<EMViewControllerPresentationContext>)rootPresentationContext;

@end
