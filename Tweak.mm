
#import <UIKit/UIKit.h>

extern void GGDOverlayBootstrap(void);

__attribute__((constructor))
static void GGDEntry(void) {
    // GGDOverlay.mm owns the actual constructor. This translation unit exists
    // separately so Theos keeps the tweak target explicit and easy to extend.
}
