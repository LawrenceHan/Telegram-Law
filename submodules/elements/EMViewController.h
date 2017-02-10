#import <UIKit/UIKit.h>

#import <Elements/EMStatusBar.h>
#import <Elements/EMNavigationBar.h>

@interface EMViewController : UIViewController

@property (nonatomic, strong, readonly) EMStatusBar *statusBar;
@property (nonatomic, strong, readonly) EMNavigationBar *navigationBar;

@end
