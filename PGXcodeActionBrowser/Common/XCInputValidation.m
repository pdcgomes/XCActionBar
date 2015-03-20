//
//  XCInputValidation.m
//  XCActionBar
//
//  Created by Pedro Gomes on 11/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCInputValidation.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL TRCheckIsEmpty(id value)
{
    return (value == nil ||
            value == [NSNull null] ||
            ([value isKindOfClass:[NSString class]] && [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) ||
            ([value respondsToSelector:@selector(count)] && [value count] == 0));
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckIsClass(id value, Class klass)
{
    return [value isKindOfClass:klass];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL TRCheckImplementsProtocol(id object, Protocol *protocol)
{
    return [object conformsToProtocol:protocol];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckContainsKey(id object, id<NSCopying> key)
{
    if([object respondsToSelector:@selector(objectForKeyedSubscript:)] == NO) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The provided object %@ doesn't support keyed subscripting", object];
    }
    
    return ([object objectForKeyedSubscript:key] != nil);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckContainsKeys(id object, NSArray *keys)
{
    if([object respondsToSelector:@selector(objectForKeyedSubscript:)] == NO) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The provided object %@ doesn't support keyed subscripting", object];
    }
    
    if(TRCheckIsEmpty(keys) == YES) {
        return NO;
    }
    
    NSSet *uniqueKeys = [NSSet setWithArray:keys];
    for(id<NSCopying> key in uniqueKeys) {
        if([object objectForKeyedSubscript:key] == nil) {
            return NO;
        }
    }
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckMinLength(NSString *value, NSUInteger minLength)
{
    return value.length >= minLength;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckMaxLength(NSString *value, NSUInteger maxLength)
{
    return value.length <= maxLength;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckExactLength(NSString *value, NSUInteger exactLength)
{
    return value.length == exactLength;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
FOUNDATION_EXPORT BOOL TRCheckLengthWithinRange(NSString *value, NSUInteger lowerConstraint, NSUInteger upperConstraint)
{
    return value.length >= lowerConstraint && value.length <= upperConstraint;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *TRSafeString(NSString *string)
{
    return (TRCheckIsEmpty(string) ? @"" : string);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
id TRSafeCollectionValue(id value)
{
    return value ?: [NSNull null];
}

#pragma mark - Error Handling Helpers

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSError *RTVBuildError(NSString *errorDomain, NSInteger errorCode, NSString *errorDescription)
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: TRSafeCollectionValue(errorDescription)};
    
    return [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSError *RTVBuildErrorWithInfo(NSString *errorDomain, NSInteger errorCode, NSString *errorDescription, NSDictionary *userInfo)
{
//    NSDictionary *mergedUserInfo = [@{NSLocalizedDescriptionKey: TRSafeCollectionValue(errorDescription)} dictionaryByMergingEntriesFromDictionary:userInfo];
    
    return [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo];
}
