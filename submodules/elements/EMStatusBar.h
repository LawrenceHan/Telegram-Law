#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EMStatusBar : NSObject

@property (nonatomic, copy) void (^changed)();

@property (nonatomic) UIStatusBarStyle style;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) CGFloat verticalOffset;

@end
