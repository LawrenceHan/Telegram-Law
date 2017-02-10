#import "EMStatusBarController.h"

@interface EMStatusBarController ()

@end

@implementation EMStatusBarController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _statusBarStyle;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    if (_statusBarStyle != statusBarStyle)
    {
        _statusBarStyle = statusBarStyle;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (bool)shouldAutorotate
{
    return true;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.view.window.layer removeAnimationForKey:@"backgroundColor"];
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    self.view.window.layer.backgroundColor = [UIColor clearColor].CGColor;
    [CATransaction commit];
    
    for (UIView *view in self.view.window.subviews)
    {
        if (view != self.view)
        {
            [view removeFromSuperview];
            break;
        }
    }
}

- (void)loadView
{
    [super loadView];
    
    self.view.opaque = false;
    self.view.backgroundColor = [UIColor clearColor];
}

@end
