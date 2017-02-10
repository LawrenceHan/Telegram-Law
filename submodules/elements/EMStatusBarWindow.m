#import "EMStatusBarWindow.h"

#import "EMStatusBarController.h"

@interface EMStatusBarWindow ()
{
    EMStatusBarController *_controller;
}

@end

@implementation EMStatusBarWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.windowLevel = 1000.0f;
        
        _controller = [[EMStatusBarController alloc] init];
        self.rootViewController = _controller;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)__unused point withEvent:(UIEvent *)__unused event
{
    return nil;
}

@end
