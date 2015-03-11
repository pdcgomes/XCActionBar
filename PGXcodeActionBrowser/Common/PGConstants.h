//
//  PGConstants.h
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 10/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGGeneralCompletionHandler)(void);
typedef void (^PGGeneralErrorHandler)(NSError *error);

#define RTVExecuteIf(_booleanExpression_, _codeBlockToExecute_) do { if(_booleanExpression_) { _codeBlockToExecute_; }; } while(0)
#define RTVExecuteIfOrFallback(_booleanExpression_, _codeBlockToExecute_, _fallbackCodeToExecute_) do { if(_booleanExpression_) { _codeBlockToExecute_; } else { _fallbackCodeToExecute_; } } while(0)

#ifdef __cplusplus

#define RTVDeclareWeakSelf(_var_) __weak __typeof(self) _var_ = self
#define RTVDeclareWeak(_object_, _var_) __weak __typeof(_object_) _var_ = _object_
#define RTVDeclareWeak2(_object_) __weak __typeof(_object_) weak_##_object_ = _object_

#else

#define RTVDeclareWeakSelf(_var_) __weak typeof(self) _var_ = self
#define RTVDeclareWeak(_object_, _var_) __weak typeof(_object_) _var_ = _object_
#define RTVDeclareWeak2(_object_) __weak typeof(_object_) weak_##_object_ = _object_

#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define TRLog(fmt, ...) NSLog((@"[ActionBrowser] %s(Line:%d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define TRCheckOption(_settings_, _option_) ((_settings_ & _option_) == _option_)
