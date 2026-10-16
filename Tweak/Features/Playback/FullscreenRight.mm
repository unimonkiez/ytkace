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
    UIButton *button = (UIButton *)sender;
    
    // Visual feedback - change button appearance
    [UIView animateWithDuration:0.2 animations:^{
        button.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.3];
        button.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
    
    // Find the YTWatchViewController in the responder chain
    UIResponder *responder = YTKACEFullscreenRightOverlay;
    UIViewController *watchVC = nil;
    
    NSMutableString *debugInfo = [NSMutableString stringWithString:@"Searching for VC...\n"];
    
    while (responder) {
        [debugInfo appendFormat:@"→ %@\n", NSStringFromClass([responder class])];
        if ([NSStringFromClass([responder class]) isEqualToString:@"YTWatchViewController"]) {
            watchVC = (UIViewController *)responder;
            [debugInfo appendString:@"✓ Found YTWatchViewController!\n"];
            break;
        }
        responder = [responder nextResponder];
    }
    
    if (!watchVC) {
        [debugInfo appendString:@"\nTrying any VC...\n"];
        responder = YTKACEFullscreenRightOverlay;
        while (responder) {
            if ([responder isKindOfClass:[UIViewController class]]) {
                watchVC = (UIViewController *)responder;
                [debugInfo appendFormat:@"✓ Found: %@\n", NSStringFromClass([watchVC class])];
                break;
            }
            responder = [responder nextResponder];
        }
    }
    
    if (!watchVC) {
        [debugInfo appendString:@"\n✗ No VC found!"];
        [self showAlertWithTitle:@"Debug Info" message:debugInfo];
        [UIView animateWithDuration:0.2 delay:0.5 options:0 animations:^{
            button.backgroundColor = [UIColor clearColor];
            button.transform = CGAffineTransformIdentity;
        } completion:nil];
        return;
    }
    
    [debugInfo appendFormat:@"\n\nRotating to Landscape Right...\n"];
    [debugInfo appendFormat:@"VC: %@\n", NSStringFromClass([watchVC class])];
    
    // Force rotation by setting device orientation
    NSNumber *value = @(UIInterfaceOrientationLandscapeRight);
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [debugInfo appendString:@"✓ Set device orientation\n"];
    
    // Tell the view controller to update its orientation
    if ([watchVC respondsToSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)]) {
        [watchVC performSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)];
        [debugInfo appendString:@"✓ Called setNeedsUpdate\n"];
    } else {
        [debugInfo appendString:@"✗ No setNeedsUpdate method\n"];
    }
    
    // Force attempt rotation
    [UIViewController attemptRotationToDeviceOrientation];
    [debugInfo appendString:@"✓ Attempted rotation"];
    
    // Show debug info
    [self showAlertWithTitle:@"Rotation Debug" message:debugInfo];
    
    // Reset button appearance
    [UIView animateWithDuration:0.2 delay:2.0 options:0 animations:^{
        button.backgroundColor = [UIColor clearColor];
        button.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = [self getTopViewController];
        if (topVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (UIViewController *)getTopViewController {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    UIViewController *topVC = window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
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
