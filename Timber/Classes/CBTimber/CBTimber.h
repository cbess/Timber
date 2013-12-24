//
//  CBTimber.h
//  Timber
//
//  Created by C. Bess on 12/23/13.
//  Copyright (c) 2013 Christopher Bess. MIT.
//

#import <Foundation/Foundation.h>

/**
 Specifies the log level.
 */
typedef NS_ENUM(NSUInteger, CBTimberLogLevel) {
    CBTimberLogLevelIgnore,
    CBTimberLogLevelVerbose,
    CBTimberLogLevelDebug,
    CBTimberLogLevelInfo,
    CBTimberLogLevelWarn,
    CBTimberLogLevelError
};

/**
 Returns YES if the specified username is the current dev/user running the app.
 @param username User's home folder name.
 @discussion Useful for blocks of logic you only want executed if running app as a particular dev/user.
 */
extern BOOL CBTIsCurrentUsername(NSString *username);

#pragma mark - Constants

/**
 Provides the message format for log output.
 @discussion Format allows: @line, @func, @message, @level, @file
 */
//static NSString *const kCBTimberLogOptionFormatKey = @"log-format";

/**
 The log level that will be logged. Logs the set level and higher.
 @discussion If set to `Info`, then `Debug` and `Verbose` will not be logged, but `Warn` and `Error` will be logged.
 */
#ifndef CBTLOG_LEVEL
#define CBTLOG_LEVEL CBTimberLogLevelIgnore
#endif

#pragma mark -

#ifdef DEBUG
#   define CBTLog(LVL, TAG, MSG, ...) \
    [CBTimber logWithLevel:LVL, tag:TAG file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ message:MSG, ##__VA_ARGS__]
#   define CBTDebugCode(BLOCK) ({ BLOCK })
#else
#   define CBTLog(LVL, TAG, MSG, ...) ;
#   define CBTDebugCode(BLOCK) ;
#endif

#define _CBT_LOG_MSG(LVL, TAG, MSG, ...) CBTLog(CBTimberLogLevel##LVL, TAG, MSG, ##__VA_ARGS__)

#pragma mark - Log Macros

#define CBTLogVerbose(MSG, ...) \
    _CBT_LOG_MSG(Verbose, nil, MSG, ##__VA_ARGS__)

#define CBTLogDebug(MSG, ...) \
    _CBT_LOG_MSG(Debug, nil, MSG, ##__VA_ARGS__)

#define CBTLogInfo(MSG, ...) \
    _CBT_LOG_MSG(Info, nil, MSG, ##__VA_ARGS__)

#define CBTLogWarn(MSG, ...) \
    _CBT_LOG_MSG(Warn, nil, MSG, ##__VA_ARGS__)

#define CBTLogError(MSG, ...) \
    _CBT_LOG_MSG(Error, nil, MSG, ##__VA_ARGS__)

// Logs non-nil errors
#define CBTLogDebugError(ERROR) \
    if (ERROR) { _CBT_LOG_MSG(Error, nil, @"!! ERROR: %@", [ERROR localizedDescription]); }

#pragma mark Log Macros w/ tagging

#define CBTLogVerboset(TAG, MSG, ...) \
    _CBT_LOG_MSG(Verbose, TAG, MSG, ##__VA_ARGS__)

#define CBTLogDebugt(TAG, MSG, ...) \
    _CBT_LOG_MSG(Debug, TAG, MSG, ##__VA_ARGS__)

#define CBTLogInfot(TAG, MSG, ...) \
    _CBT_LOG_MSG(Info, TAG, MSG, ##__VA_ARGS__)

#define CBTLogWarnt(TAG, MSG, ...) \
    _CBT_LOG_MSG(Warn, TAG, MSG, ##__VA_ARGS__)

#define CBTLogErrort(TAG, MSG, ...) \
    _CBT_LOG_MSG(Error, TAG, MSG, ##__VA_ARGS__)

#pragma mark - Log Class

@protocol CBTimberLogMachine;

/**
 Represents timber logging functionality.
 */
@interface CBTimber : NSObject

#pragma mark Log Machines

- (void)addLogMachine:(id<CBTimberLogMachine>)machine;
- (void)removeLogMachineWithIdentifier:(NSString *)identifier;
- (void)removeLogMachine:(id<CBTimberLogMachine>)machine;

#pragma mark Configure

/**
 Sets the log tag.
 @param tag The regular expression pattern the tag must match (case insensitive).
 @param username The username (home folder name) of the user/dev this log tag applies to. Pass nil to ignore the username.
 @discussion If non-nil, it will filter the logs to only log matching tags.
 */
+ (void)setLogTag:(NSString *)tag forUsername:(NSString *)username;
+ (void)setLogTag:(NSString *)tag;
+ (NSString *)logTag;

/**
 Sets the log function/method name.
 @param functionName The regular expression pattern the function or method name must match to be logged (case insensitive).
 @param username The username (home folder name) of the user/dev this log tag applies to. Pass nil to ignore the username.
 @discussion If non-nil, it will filter the logs to only log matching names.
 */
+ (void)setLogFunctionName:(NSString *)functionName forUsername:(NSString *)username;
+ (void)setLogFunctionName:(NSString *)functionName;
+ (NSString *)logFunctionName;

#pragma mark Logging

/**
 Logs the specified meta data for the given message.
 @discussion It is best to use the provided log macros.
 */
+ (void)logWithLevel:(NSUInteger)level
                 tag:(NSString *)tag
                file:(const char *)file
            function:(const char *)function
                line:(int)line
              message:(NSString *)message, ...;

/**
 Logs the specified data with the given format and format args.
 @discussion It is best to use the provided log macros.
 */
+ (void)logWithLevel:(NSUInteger)level
                 tag:(NSString *)tag
                file:(const char *)file
            function:(const char *)function
                line:(int)line
              format:(NSString *)format
                args:(va_list)argList;

@end

/**
 Represents an object that processes logs.
 */
@protocol CBTimberLogMachine <NSObject>

/**
 Name of the receiver.
 */
- (NSString *)name;

/**
 The identifier for the receiver.
 @discussion Should be in the form of a FQDN (domain). Example: com.cbess.logger
 */
- (NSString *)identifier;

@end
