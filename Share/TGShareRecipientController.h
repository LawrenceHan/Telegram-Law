#import <UIKit/UIKit.h>

@class TGShareContext;

@interface TGShareRecipientController : UIViewController

- (void)setShareContext:(TGShareContext *)shareContext;

- (void)proceed;

@end
