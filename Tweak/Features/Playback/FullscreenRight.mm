#import "../../YTKACE.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"
#import "../../UI/OverlayButtonHost.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>

static UIView *YTKACEFullscreenRightOverlay;

@interface YTKACEFullscreenRightController : NSObject
+ (instancetype)sharedController;
- (void)rotateToLandscapeRight:(id)sender;
- (void)setOverlay:(UIView *)overlay;
@end

@implementation YTKACEFullscreenRightController

+ (instancetype)sharedController {
    static YTKACEFullscreenRightController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [YTKACEFullscreenRightController new];
    });
    return controller;
}

- (void)setOverlay:(UIView *)overlay {
    YTKACEFullscreenRightOverlay = overlay;
}

- (UIViewController *)viewControllerForOverlay:(UIView *)overlay {
    UIResponder *responder = overlay;
    while (responder != nil) {
        if ([responder isKindOfClass:UIViewController.class]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

- (void)rotateToLandscapeRight:(id)sender {
    UIView *overlay = YTKACEFullscreenRightOverlay;
    if (overlay == nil) return;
    
    UIViewController *vc = [self viewControllerForOverlay:overlay];
    if (vc == nil) return;
    
    // Force rotation to landscape right by setting device orientation
    NSNumber *landscapeRight = @(UIDeviceOrientationLandscapeRight);
    [[UIDevice currentDevice] setValue:landscapeRight forKey:@"orientation"];
    
    // Trigger rotation on the view controller
    if ([vc respondsToSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)]) {
        [vc performSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)];
    }
    
    // Also try to update the preferred orientation
    SEL attemptRotation = NSSelectorFromString(@"attemptRotationToDeviceOrientation");
    if ([UIViewController respondsToSelector:attemptRotation]) {
        ((void (*)(id, SEL))objc_msgSend)(UIViewController.class, attemptRotation);
    }
}

@end

void YTKACEInstallFullscreenRightHooks(void) {
    YTKACERegisterOverlayConfigurator(@"fullscreenright", ^(UIView *overlay, UIStackView *stack) {
        [YTKACEFullscreenRightController.sharedController setOverlay:overlay];
        UIButton *button = YTKACEOverlayButton(
            stack,
            @"YTKACE Fullscreen Right",
            @"arrow.clockwise",
            YTKACEFullscreenRightController.sharedController,
            @selector(rotateToLandscapeRight:)
        );
        button.hidden = !YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight");
    });
}
