
#pragma once
#import <UIKit/UIKit.h>
#include "GGDIl2Cpp.hpp"

@interface GGDPlayerSnapshot : NSObject
@property(nonatomic, assign) void* object;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* role;
@property(nonatomic, strong) NSString* team;
@property(nonatomic, assign) CGPoint worldOrScreen;
@property(nonatomic, assign) BOOL hasPosition;
@end

@interface GGDCore : NSObject
@property(nonatomic, readonly) BOOL il2cppReady;
@property(nonatomic, readonly) BOOL gameReady;
@property(nonatomic, readonly) NSUInteger playerCount;
@property(nonatomic, readonly) NSArray<GGDPlayerSnapshot*>* snapshots;
@property(nonatomic, copy, readonly) NSString* statusLine;
+ (instancetype)shared;
- (void)start;
- (void)tick;
@end
