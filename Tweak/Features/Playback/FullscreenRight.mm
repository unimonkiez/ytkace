#import "../../YTKACE.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"

#import <UIKit/UIKit.h>

static IMP OriginalSupportedOrientations;
static IMP OriginalPreferredOrientation;
static IMP OriginalShouldAutorotate;

static UIInterfaceOrientationMask YTKACESupportedOrientations(id receiver, SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    if (OriginalSupportedOrientations) {
        return ((UIInterfaceOrientationMask (*)(id, SEL))OriginalSupportedOrientations)(receiver, selector);
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

static UIInterfaceOrientation YTKACEPreferredOrientation(id receiver, SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationLandscapeRight;
    }
    if (OriginalPreferredOrientation) {
        return ((UIInterfaceOrientation (*)(id, SEL))OriginalPreferredOrientation)(receiver, selector);
    }
    return UIInterfaceOrientationLandscapeLeft;
}

static BOOL YTKACEShouldAutorotate(id receiver, SEL selector) {
    if (OriginalShouldAutorotate) {
        return ((BOOL (*)(id, SEL))OriginalShouldAutorotate)(receiver, selector);
    }
    return YES;
}

void YTKACEInstallFullscreenRightHooks(void) {
    if (!YTKACEInstallInstanceHook(@"YTWatchViewController",
                                   @"supportedInterfaceOrientations",
                                   (IMP)YTKACESupportedOrientations,
                                   &OriginalSupportedOrientations)) {
        YTKACEAddInstanceMethod(@"YTWatchViewController",
                               @"supportedInterfaceOrientations",
                               (IMP)YTKACESupportedOrientations,
                               "Q@:");
    }
    
    if (!YTKACEInstallInstanceHook(@"YTWatchViewController",
                                   @"preferredInterfaceOrientationForPresentation",
                                   (IMP)YTKACEPreferredOrientation,
                                   &OriginalPreferredOrientation)) {
        YTKACEAddInstanceMethod(@"YTWatchViewController",
                               @"preferredInterfaceOrientationForPresentation",
                               (IMP)YTKACEPreferredOrientation,
                               "q@:");
    }
    
    if (!YTKACEInstallInstanceHook(@"YTWatchViewController",
                                   @"shouldAutorotate",
                                   (IMP)YTKACEShouldAutorotate,
                                   &OriginalShouldAutorotate)) {
        YTKACEAddInstanceMethod(@"YTWatchViewController",
                               @"shouldAutorotate",
                               (IMP)YTKACEShouldAutorotate,
                               "B@:");
    }
}
