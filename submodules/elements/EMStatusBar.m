#import "EMStatusBar.h"

@implementation EMStatusBar

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _style = UIStatusBarStyleDefault;
        _alpha = 1.0f;
        _verticalOffset = 0.0f;
    }
    return self;
}

- (void)setStyle:(UIStatusBarStyle)style
{
    if (_style != style)
    {
        _style = style;
        if (_changed)
            _changed();
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    if (_alpha != alpha)
    {
        _alpha = alpha;
        if (_changed)
            _changed();
    }
}

- (void)setVerticalOffset:(CGFloat)verticalOffset
{
    if (ABS(_verticalOffset - verticalOffset) > FLT_EPSILON)
    {
        _verticalOffset = verticalOffset;
        if (_changed)
            _changed();
    }
}

@end
