#import "../../YTKACE.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"
#import "../../UI/OverlayButtonHost.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>

static IMP OriginalSupportedOrientations;
static IMP OriginalPreferredOrientation;

static UIInterfaceOrientationMask YTKACESupportedOrientations(id self, SEL _cmd) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    
    if (OriginalSupportedOrientations) {
        return ((UIInterfaceOrientationMask (*)(id, SEL))OriginalSupportedOrientations)(self, _cmd);
    }
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

static UIInterfaceOrientation YTKACEPreferredOrientation(id self, SEL _cmd) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationLandscapeRight;
    }
    
    if (OriginalPreferredOrientation) {
        return ((UIInterfaceOrientation (*)(id, SEL))OriginalPreferredOrientation)(self, _cmd);
    }
    
    return UIInterfaceOrientationLandscapeLeft;
}

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

- (void)rotateToLandscapeRight:(id)sender {
    // Find the YTWatchViewController in the responder chain
    UIResponder *responder = YTKACEFullscreenRightOverlay;
    UIViewController *watchVC = nil;
    
    while (responder) {
        if ([NSStringFromClass([responder class]) isEqualToString:@"YTWatchViewController"]) {
            watchVC = (UIViewController *)responder;
            break;
        }
        responder = [responder nextResponder];
    }
    
    if (!watchVC) {
        // Try to find any view controller
        responder = YTKACEFullscreenRightOverlay;
        while (responder) {
            if ([responder isKindOfClass:[UIViewController class]]) {
                watchVC = (UIViewController *)responder;
                break;
            }
            responder = [responder nextResponder];
        }
    }
    
    if (!watchVC) return;
    
    // Force rotation by setting device orientation
    NSNumber *value = @(UIInterfaceOrientationLandscapeRight);
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    // Tell the view controller to update its orientation
    if ([watchVC respondsToSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)]) {
        [watchVC performSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)];
    }
    
    // Force attempt rotation
    [UIViewController attemptRotationToDeviceOrientation];
}

@end

void YTKACEInstallFullscreenRightHooks(void) {
    // Hook YTWatchViewController orientation methods
    Class watchVCClass = NSClassFromString(@"YTWatchViewController");
    if (watchVCClass) {
        // Hook supportedInterfaceOrientations
        Method supportedOrientationsMethod = class_getInstanceMethod(watchVCClass, @selector(supportedInterfaceOrientations));
        if (supportedOrientationsMethod) {
            OriginalSupportedOrientations = method_getImplementation(supportedOrientationsMethod);
            method_setImplementation(supportedOrientationsMethod, (IMP)YTKACESupportedOrientations);
        }
        
        // Hook preferredInterfaceOrientationForPresentation
        Method preferredOrientationMethod = class_getInstanceMethod(watchVCClass, @selector(preferredInterfaceOrientationForPresentation));
        if (preferredOrientationMethod) {
            OriginalPreferredOrientation = method_getImplementation(preferredOrientationMethod);
            method_setImplementation(preferredOrientationMethod, (IMP)YTKACEPreferredOrientation);
        }
    }
    
    // Add overlay button
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
