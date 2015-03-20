//
//  XCInputValidation.h
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT BOOL TRCheckIsEmpty(id value);
FOUNDATION_EXPORT BOOL TRCheckIsClass(id value, Class klass);
FOUNDATION_EXPORT BOOL TRCheckImplementsProtocol(id object, Protocol *protocol);

FOUNDATION_EXPORT BOOL TRCheckContainsKey(id object, id<NSCopying> key);
FOUNDATION_EXPORT BOOL TRCheckContainsKeys(id object, NSArray *keys);

FOUNDATION_EXPORT BOOL TRCheckMinLength(NSString *value, NSUInteger minLength);
FOUNDATION_EXPORT BOOL TRCheckMaxLength(NSString *value, NSUInteger maxLength);
FOUNDATION_EXPORT BOOL TRCheckExactLength(NSString *value, NSUInteger exactLength);
FOUNDATION_EXPORT BOOL TRCheckLengthRange(NSString *value, NSUInteger lowerConstraint, NSUInteger upperConstraint);

FOUNDATION_EXPORT NSString *TRSafeString(NSString *string);
FOUNDATION_EXPORT id TRSafeCollectionValue(id value);

#define TRRangeOfString(_str_) (NSMakeRange(0, _str_.length))

////////////////////////////////////////////////////////////////////////////////
// Error Handling Helpers
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT NSError *RTVBuildError(NSString *errorDomain, NSInteger errorCode, NSString *errorDescription);
FOUNDATION_EXPORT NSError *RTVBuildErrorWithInfo(NSString *errorDomain, NSInteger errorCode, NSString *errorDescription, NSDictionary *userInfo);
