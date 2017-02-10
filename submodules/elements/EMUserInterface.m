#import "EMUserInterface.h"

#import "EMStatusBarWindow.h"
#import "EMViewController.h"

@interface EMUserInterfaceRootPresentationContext : NSObject <EMViewControllerPresentationContext>
{
    UIWindow *_mainWindow;
}

- (instancetype)initWithMainWindow:(UIWindow *)mainWindow;

@end

@interface EMUserInterface ()
{
    UIWindow *_mainWindow;
    EMStatusBarWindow *_statusBarWindow;
    EMUserInterfaceRootPresentationContext *_rootPresentationContext;
}

@end

@implementation EMUserInterface

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _mainWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _statusBarWindow = [[EMStatusBarWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        _rootPresentationContext = [[EMUserInterfaceRootPresentationContext alloc] initWithMainWindow:_mainWindow];
    }
    return self;
}

- (void)activate
{
    _statusBarWindow.hidden = false;
    [_mainWindow makeKeyAndVisible];
}

- (id<EMViewControllerPresentationContext>)rootPresentationContext
{
    return _rootPresentationContext;
}

@end

@implementation EMUserInterfaceRootPresentationContext

- (instancetype)initWithMainWindow:(UIWindow *)mainWindow
{
    self = [super init];
    if (self != nil)
    {
        _mainWindow = mainWindow;
    }
    return self;
}

- (void)presentController:(EMViewController *)controller
{
    _mainWindow.rootViewController = controller;
}

@end

