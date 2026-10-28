#import "CGVirtualDisplayBridge.h"

BOOL ExDisplayPostEvent(CGEventRef event, CGEventTapLocation tap) {
    if (!event) return NO;
    @try {
        CGEventPost(tap, event);
        return YES;
    } @catch (NSException *ex) {
        NSLog(@"[ExDisplay][Input] CGEventPost exception: %@ — %@", ex.name, ex.reason);
        return NO;
    }
}
