
#import "GGDCore.hpp"
#import <QuartzCore/QuartzCore.h>

@interface GGDOverlayView : UIView
@property(nonatomic,strong) UILabel* title;
@property(nonatomic,strong) UILabel* detail;
@property(nonatomic,strong) UIButton* toggle;
@property(nonatomic,strong) UIView* panel;
@property(nonatomic,strong) CADisplayLink* link;
@end

@implementation GGDOverlayView

- (instancetype)initWithFrame:(CGRect)f {
    if ((self=[super initWithFrame:f])) {
        self.userInteractionEnabled = YES;

        _toggle=[UIButton buttonWithType:UIButtonTypeSystem];
        _toggle.frame=CGRectMake(12,12,128,34);
        _toggle.layer.cornerRadius=17;
        _toggle.backgroundColor=[UIColor colorWithWhite:0.05 alpha:0.88];
        [_toggle setTitle:@"GGD  检测中" forState:UIControlStateNormal];
        [_toggle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self addSubview:_toggle];
        [_toggle addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

        _panel=[[UIView alloc] initWithFrame:CGRectMake(12,54,300,178)];
        _panel.backgroundColor=[UIColor colorWithWhite:0.04 alpha:0.93];
        _panel.layer.cornerRadius=14;
        _panel.hidden=YES;
        [self addSubview:_panel];

        _title=[[UILabel alloc] initWithFrame:CGRectMake(14,10,270,28)];
        _title.text=@"GGD Identity Overlay";
        _title.textColor=UIColor.whiteColor;
        _title.font=[UIFont boldSystemFontOfSize:16];
        [_panel addSubview:_title];

        _detail=[[UILabel alloc] initWithFrame:CGRectMake(14,42,270,124)];
        _detail.numberOfLines=0;
        _detail.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        _detail.textColor=[UIColor colorWithWhite:0.88 alpha:1];
        [_panel addSubview:_detail];

        UIPanGestureRecognizer* pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [_toggle addGestureRecognizer:pan];

        _link=[CADisplayLink displayLinkWithTarget:self selector:@selector(refresh)];
        [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];

    if (hit == self) {
        return nil;
    }

    return hit;
}

- (void)dealloc { [_link invalidate]; }

- (void)togglePanel { _panel.hidden=!_panel.hidden; }

- (void)move:(UIPanGestureRecognizer*)g {
    CGPoint p=[g translationInView:self];
    CGRect r=_toggle.frame;
    r.origin.x += p.x; r.origin.y += p.y;
    _toggle.frame=r;
    _panel.frame=CGRectMake(r.origin.x,r.origin.y+r.size.height+8,_panel.frame.size.width,_panel.frame.size.height);
    [g setTranslation:CGPointMake(0, 0) inView:self];
}

- (void)refresh {
    GGDCore* c=GGDCore.shared;
    [c tick];
    BOOL ready=c.il2cppReady;
    [_toggle setTitle:(ready?@"GGD  已加载":@"GGD  检测中") forState:UIControlStateNormal];
    NSMutableString* text=[NSMutableString stringWithFormat:
                  @"注入: YES\nUnity/IL2CPP: %@\nGame: %@\nPlayers: %lu\n状态: %@",
                  ready?@"OK":@"WAIT", c.gameReady?@"OK":@"WAIT",
                  (unsigned long)c.playerCount, c.statusLine];
    NSUInteger shown=0;
    for (GGDPlayerSnapshot* p in c.snapshots) {
        if (shown++>=6) break;
        [text appendFormat:@"\n%@  |  %@", p.name ?: @"?", p.role ?: @"?"];
    }
    _detail.text=text;
}

@end

static GGDOverlayView* gOverlay;

static UIWindow* FindAppWindow(void) {
    UIApplication* app=UIApplication.sharedApplication;
    if (@available(iOS 13.0,*)) {
        for (UIScene* scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateUnattached) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene* windowScene=(UIWindowScene*)scene;
            for (UIWindow* w in windowScene.windows) {
                if (!w.hidden && w.rootViewController) return w;
            }
        }
    }
    for (UIWindow* w in app.windows) if (!w.hidden) return w;
    return app.keyWindow;
}

static void InstallOverlay(void) {
    UIWindow* w=FindAppWindow();
    if (!w || !w.rootViewController) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.5*NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ InstallOverlay(); });
        return;
    }
    if (gOverlay) return;
    gOverlay=[[GGDOverlayView alloc] initWithFrame:w.bounds];
    gOverlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [w addSubview:gOverlay];
    [GGDCore.shared start];
}

__attribute__((constructor))
static void GGDOverlayInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ InstallOverlay(); });
}
