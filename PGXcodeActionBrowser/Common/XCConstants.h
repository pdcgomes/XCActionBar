//
//  XCConstants.h
//  XCActionBar
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGGeneralCompletionHandler)(void);
typedef void (^PGGeneralErrorHandler)(NSError *error);

#define XCExecuteIf(_booleanExpression_, _codeBlockToExecute_) do { if(_booleanExpression_) { _codeBlockToExecute_; }; } while(0)
#define XCExecuteIfOrFallback(_booleanExpression_, _codeBlockToExecute_, _fallbackCodeToExecute_) do { if(_booleanExpression_) { _codeBlockToExecute_; } else { _fallbackCodeToExecute_; } } while(0)

#ifdef __cplusplus

#define XCDeclareWeakSelf(_var_) __weak __typeof(self) _var_ = self
#define XCDeclareWeak(_object_, _var_) __weak __typeof(_object_) _var_ = _object_
#define XCDeclareWeak2(_object_) __weak __typeof(_object_) weak_##_object_ = _object_

#else

#define XCDeclareWeakSelf(_var_) __weak typeof(self) _var_ = self
#define XCDeclareWeak(_object_, _var_) __weak typeof(_object_) _var_ = _object_
#define XCDeclareWeak2(_object_) __weak typeof(_object_) weak_##_object_ = _object_

#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#ifdef DEBUG
#define XCLog(fmt, ...) NSLog((@"[ActionBrowser] %s(Line:%d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else   
#define XCLog(fmt, ...) /* */
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define XCCheckOption(_settings_, _option_) ((_settings_ & _option_) == _option_)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define XCReturnUnless(condition) if(!(condition)) { return; }
#define XCReturnFalseUnless(condition) if(!(condition)) { return NO; }
