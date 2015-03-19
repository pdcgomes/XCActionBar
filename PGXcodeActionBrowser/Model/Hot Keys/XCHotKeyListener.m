//
//  XCHotKeyListener.m
//  XCActionBar
//
//  Created by Pedro Gomes on 18/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCHotKeyListener.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const XCHotKeyListenerHotKeyMaskKey  = @"XCHotKeyListenerHotKeyMask";
NSString *const XCHotKeyListenerRepeatCountKey = @"XCHotKeyListenerRepeatCount";
NSString *const XCHotKeyListenerRepeatDelayKey = @"XCHotKeyListenerRepeatDelay";

// 63 fn L

// 55 cmd L
// 54 cmd R

// 58 opt L
// 61 opt R

// 59 ctrl L
// 56 shift L
// 60 shift R

//    NSAlphaShiftKeyMask         = 1 << 16,
//    NSShiftKeyMask              = 1 << 17,
//    NSControlKeyMask            = 1 << 18,
//    NSAlternateKeyMask          = 1 << 19,
//    NSCommandKeyMask            = 1 << 20,
//    NSNumericPadKeyMask         = 1 << 21,
//    NSHelpKeyMask               = 1 << 22,
//    NSFunctionKeyMask           = 1 << 23,

////////////////////////////////////////////////////////////////////////////////
// We currently only support one hotkey
////////////////////////////////////////////////////////////////////////////////
NSArray *XCKeyCodesFromModifierMask(NSEventModifierFlags flag)
{
    switch(flag) {
        case NSAlternateKeyMask:    return @[@(58), @(61)];
        case NSCommandKeyMask:      return @[@(54), @(55)];
        case NSControlKeyMask:      return @[@(59)  /* */];
        case NSFunctionKeyMask:     return @[@(63)  /* */];
        case NSShiftKeyMask:        return @[@(56), @(60)];
            
        default: return nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCHotKeyListener ()

@property (nonatomic,   weak) id  target;
@property (nonatomic        ) SEL action;

@property (nonatomic,   copy) XCHotKeyListenerHandler handler;

@property (nonatomic        ) id eventMonitor;

@property (nonatomic        ) NSArray        *hotKeyCodes;
@property (nonatomic, assign) NSUInteger     repeatCount;
@property (nonatomic, assign) NSTimeInterval repeatDelay;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCHotKeyListener

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validateConfiguration:(NSDictionary *)configuration error:(NSError **)error
{
    BOOL success = (TRCheckIsEmpty(configuration) == NO &&
                    TRCheckContainsKey(configuration, XCHotKeyListenerHotKeyMaskKey)    &&
                    TRCheckContainsKey(configuration, XCHotKeyListenerRepeatCountKey)   &&
                    TRCheckContainsKey(configuration, XCHotKeyListenerRepeatDelayKey));
    if(success == NO) {
        // build error
        return NO;
    }

    if([configuration[XCHotKeyListenerRepeatCountKey] integerValue]  < 2 ||
       [configuration[XCHotKeyListenerRepeatCountKey] integerValue]  > 3) {
        return NO;
    }

    if([configuration[XCHotKeyListenerRepeatDelayKey] doubleValue] < (double)0.05 ||
       [configuration[XCHotKeyListenerRepeatDelayKey] doubleValue] > (double)0.50) {
        return NO;
    }

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithConfiguration:(NSDictionary *)configuration handler:(XCHotKeyListenerHandler)handler;
{
    NSAssert([XCHotKeyListener validateConfiguration:configuration error:nil], @"");
    
    NSParameterAssert(handler != nil);
    
    if((self = [super init])) {
        self.handler = handler;
        
        self.hotKeyCodes = XCKeyCodesFromModifierMask([configuration[XCHotKeyListenerHotKeyMaskKey] unsignedIntegerValue]);
        self.repeatCount = [configuration[XCHotKeyListenerRepeatCountKey] integerValue];
        self.repeatDelay = [configuration[XCHotKeyListenerRepeatDelayKey] doubleValue];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithConfiguration:(NSDictionary *)configuration target:(id)target action:(SEL)action;
{
    NSAssert([XCHotKeyListener validateConfiguration:configuration error:nil], @"");

    NSParameterAssert(target != nil);
    NSParameterAssert(action != nil);
    
    if((self = [super init])) {
        self.target = target;
        self.action = action;
        
        self.hotKeyCodes = XCKeyCodesFromModifierMask([configuration[XCHotKeyListenerHotKeyMaskKey] unsignedIntegerValue]);
        self.repeatCount = [configuration[XCHotKeyListenerRepeatCountKey] integerValue];
        self.repeatDelay = [configuration[XCHotKeyListenerRepeatDelayKey] doubleValue];
    }
    return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define NSFlagsChangedMaskOff (1 << 8) // need to figure out what values I actually need to get this
- (BOOL)startListening
{
    TR_RETURN_FALSE_UNLESS(self.eventMonitor == nil);

    RTVDeclareWeakSelf(weakSelf);

    __block NSUInteger hotKeyPressCount = 0;
    __block NSTimeInterval keyDownTS    = 0;
    __block BOOL hotKeyDepressed        = false;

    void(^XCResetHotKeyState)(void) = ^ {
        hotKeyDepressed  = false;
        hotKeyPressCount = 0;
        keyDownTS        = 0;
    };

    [NSEvent addLocalMonitorForEventsMatchingMask:(NSFlagsChangedMask) handler:^NSEvent *(NSEvent *event) {
//        TRLog(@"<EventMonitor>, <type=%@>, <keyCode=%@>, <e=%@>", @(event.type), @(event.keyCode), event);
        
        BOOL hotKeyPressed = ((event.keyCode == [weakSelf.hotKeyCodes[0] unsignedCharValue]) ||
                              (weakSelf.hotKeyCodes.count > 1 &&
                               event.keyCode == [weakSelf.hotKeyCodes[1] unsignedCharValue]));
        if(hotKeyPressed == NO) {
            XCResetHotKeyState();
            return event;
        }
        
        if(event.modifierFlags == NSFlagsChangedMaskOff) {
            hotKeyDepressed = false;
            
            NSTimeInterval interval = (event.timestamp - keyDownTS);
            if(interval <= weakSelf.repeatDelay) hotKeyPressCount++;
            else XCResetHotKeyState();
            
            if(hotKeyPressCount >= weakSelf.repeatCount) {
                XCResetHotKeyState();
                [self notifyListener];
            }
        }
        else {
            hotKeyDepressed = true;
            keyDownTS = event.timestamp;
        }
        return event;
    }];

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)stopListening
{
    TR_RETURN_FALSE_UNLESS(self.eventMonitor != nil);
    
    return YES;
}

#pragma mark - Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)notifyListener
{
    if(self.target && self.action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action];
#pragma clang diagnostic pop
    }
    else self.handler();
}

@end
