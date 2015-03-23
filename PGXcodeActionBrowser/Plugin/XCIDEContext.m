//
//  XCIDEContext.m
//  XCXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionBarConfiguration.h"
#import "XCUtils.h"
#import "XCIDEContext.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const XCActionInfoTitleKey    = @"XCActionTitle";
NSString *const XCActionInfoSubtitleKey = @"XCActionSubtitle";
NSString *const XCActionInfoSummaryKey  = @"XCActionSummary";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCIDEContext () <NSUserNotificationCenterDelegate>

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCIDEContext

@synthesize configuration, editorDocument, workspaceDocument, sourceCodeDocument, sourceCodeTextView;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSRange)retrieveTextSelectionRange
{
    NSArray *selectedTextRanges = [self.sourceCodeTextView selectedRanges];
    if(TRCheckIsEmpty(selectedTextRanges) == YES) return (NSRange){NSNotFound, -1};
    
    NSRange rangeForSelectedText = [selectedTextRanges.firstObject rangeValue];

    return rangeForSelectedText;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)retrieveTextSelectionRanges
{
    return [self.sourceCodeTextView selectedRanges];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)retrieveTextSelection
{
    NSRange rangeForSelectedText = [self retrieveTextSelectionRange];
    if(rangeForSelectedText.location == NSNotFound) return nil;
    
    return [self.sourceCodeTextView.textStorage.string substringWithRange:rangeForSelectedText];    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)retrievePasteboardTextContents
{
    NSArray *items = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class], [NSAttributedString class]] options:nil];

    return items.firstObject;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)copyContentsToPasteboard:(id<NSPasteboardWriting>)contents
{
    if(contents == nil) return NO;

    [[NSPasteboard generalPasteboard] clearContents];
    return [[NSPasteboard generalPasteboard] writeObjects:@[contents]];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)sendActionExecutionConfirmationWithInfo:(NSDictionary *)info
{
    XCReturnFalseUnless(self.configuration.userAlertsEnabledGlobally);
    XCReturnFalseUnless(self.configuration.userAlertsEnabledForActions);
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title           = info[XCActionInfoTitleKey];
    notification.subtitle        = info[XCActionInfoSubtitleKey];
    notification.informativeText = info[XCActionInfoSummaryKey];
    notification.userInfo        = nil;

    NSUserNotificationCenter *notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    notificationCenter.delegate = self;
    
    [notificationCenter scheduleNotification:notification];

    return YES;
}

#pragma mark - NSUserNotificationCenterDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
