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
    return OriginalSupportedOrientations == NULL
        ? UIInterfaceOrientationMaskLandscapeLeft
        : ((UIInterfaceOrientationMask (*)(id, SEL))OriginalSupportedOrientations)(receiver, selector);
}

static UIInterfaceOrientation YTKACEPreferredOrientation(id receiver, SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Playback.FullscreenRight")) {
        return UIInterfaceOrientationLandscapeRight;
    }
    return OriginalPreferredOrientation == NULL
        ? UIInterfaceOrientationLandscapeLeft
        : ((UIInterfaceOrientation (*)(id, SEL))OriginalPreferredOrientation)(receiver, selector);
}

void YTKACEInstallFullscreenRightHooks(void) {
    YTKACEInstallInstanceHook(@"YTWatchViewController",
                              @"supportedInterfaceOrientations",
                              (IMP)YTKACESupportedOrientations,
                              &OriginalSupportedOrientations);
    YTKACEInstallInstanceHook(@"YTWatchViewController",
                              @"preferredInterfaceOrientationForPresentation",
                              (IMP)YTKACEPreferredOrientation,
                              &OriginalPreferredOrientation);
}
