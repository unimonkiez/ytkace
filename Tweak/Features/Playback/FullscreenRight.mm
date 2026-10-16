#import "../../YTKACE.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"

#import <UIKit/UIKit.h>

static IMP OriginalSupportedOrientations;
static IMP OriginalPreferredOrientation;

static UIInterfaceOrientationMask YTKACESupportedOrientations(id receiver, SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    if (OriginalSupportedOrientations) {
        return ((UIInterfaceOrientationMask (*)(id, SEL))OriginalSupportedOrientations)(receiver, selector);
    }
    return UIInterfaceOrientationMaskLandscapeLeft;
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
}
