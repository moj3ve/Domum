#import "DOMController.h"
#import "DOMSettings.h"
#import <version.h>

static inline void initializeTweak(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [DOMController mainController];
}

%group iOS9
%hook SBScreenShotter
- (void)saveScreenshot:(BOOL)save {
    [[DOMController mainController] hideButtonForScreenshot];
    %orig;
}
%end
%end


%group iOS93
%hook SBScreenshotManager
- (void)saveScreenshotsWithCompletion:(id)completion {
    [[DOMController mainController] hideButtonForScreenshot];
    %orig;
}
%end
%end

%ctor {
    if (IS_IOS_OR_NEWER(iOS_9_3)) {
        %init(iOS93);
    } else {
        %init(iOS9);
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &initializeTweak, CFSTR("SBSpringBoardDidLaunchNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    [DOMSettings sharedSettings];
}