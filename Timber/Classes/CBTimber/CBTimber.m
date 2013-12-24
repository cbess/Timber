//
//  CBTimber.m
//  Timber
//
//  Created by C. Bess on 12/23/13.
//  Copyright (c) 2013 Christopher Bess. MIT.
//

#import "CBTimber.h"

BOOL CBTIsCurrentUsername(NSString *username)
{
#ifndef DEBUG
    return NO;
#endif
    
#if TARGET_IPHONE_SIMULATOR
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
    return [path hasPrefix:[@"/Users/" stringByAppendingPathComponent:username]];
#else
    return NO;
#endif
}

void CBTLogMessage(NSString *message)
{
    static dispatch_queue_t logQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logQueue = dispatch_queue_create("timber.logging", NULL);
    });
    
    // send to normal log mechanism
    dispatch_sync(logQueue, ^{ @autoreleasepool {
        NSLog(@"%@", message);
    }});
}

static NSRegularExpression *gLogTagRegex = nil;
static NSRegularExpression *gLogFunctionNameRegex = nil;

@implementation CBTimber

#pragma mark - Config

+ (void)setLogRegexWithPattern:(NSString *)pattern forUsername:(NSString *)username block:(void(^)(id regex))regexBlock
{
    if (username.length && !CBTIsCurrentUsername(username))
    {
        regexBlock(nil);
        return;
    }
    
    // clear it, if empty
    if (!pattern.length)
    {
        regexBlock(nil);
        return;
    }
    
    NSRegularExpression *regex = nil;
    NSError *error = nil;
    regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&error];
    regexBlock(regex);
    
    if (error)
    {
        CBTLogMessage([NSString stringWithFormat:@"!! Timber error pattern=%@ error=%@",
                       pattern, [error localizedDescription]]);
    }
}

#pragma mark Function filter

+ (NSString *)logFunctionName
{
    return gLogFunctionNameRegex.pattern;
}

+ (void)setLogFunctionName:(NSString *)functionName forUsername:(NSString *)username
{
    [self setLogRegexWithPattern:functionName forUsername:username block:^(id regex) {
        if (regex)
        {
            gLogFunctionNameRegex = regex;
            CBTLogMessage([@"++ Timber function filter: " stringByAppendingString:functionName]);
        }
    }];
}

+ (void)setLogFunctionName:(NSString *)functionName
{
    [self setLogFunctionName:functionName forUsername:nil];
}

#pragma mark Tag Filter

+ (NSString *)logTag
{
    return gLogTagRegex.pattern;
}

+ (void)setLogTag:(NSString *)tag forUsername:(NSString *)username
{
    [self setLogRegexWithPattern:tag forUsername:username block:^(id regex) {
        if (regex)
        {
            gLogTagRegex = regex;
            CBTLogMessage([@"++ Timber tag filter: " stringByAppendingString:tag]);
        }
    }];
}

+ (void)setLogTag:(NSString *)tag
{
    [self setLogTag:tag forUsername:nil];
}

#pragma mark - Misc

+ (BOOL)canLogWithTag:(NSString *)tag
{
    if ([gLogTagRegex numberOfMatchesInString:tag options:0 range:NSMakeRange(0, tag.length)])
        return YES;
    
    return NO;
}

+ (BOOL)canLogWithFunction:(NSString *)name
{
    if ([gLogFunctionNameRegex numberOfMatchesInString:name options:0 range:NSMakeRange(0, name.length)])
        return YES;
    
    return NO;
}

+ (BOOL)canLogWithTag:(NSString *)tag function:(const char *)functionName
{
    // check tag
    if ([self logTag].length)
    {
        if (tag.length)
        {
            return [self canLogWithTag:tag];
        }
        else
        {
            // tag must be provided
            return NO;
        }
    }
    
    // check function name
    if ([self logFunctionName].length)
    {
        if (functionName && strlen(functionName))
        {
            NSString *funcName = [NSString stringWithUTF8String:functionName];
            return [self canLogWithFunction:funcName];
        }
        else
        {
            // no function name, then skip log
            return NO;
        }
    }
    
    return YES;
}

+ (NSString *)logMessageStringUsingOptionsWithMessage:(NSString *)message level:(int)level file:(const char *)file function:(const char *)function line:(int)line
{
    NSString *levelName = [NSString string];
    switch (level)
    {
        case CBTimberLogLevelVerbose:
            break;
            
        case CBTimberLogLevelDebug:
            levelName = @"debug";
            break;
            
        case CBTimberLogLevelInfo:
            levelName = @"info";
            break;
            
        case CBTimberLogLevelWarn:
            levelName = @"*Warning*";
            break;
            
        case CBTimberLogLevelError:
            levelName = @"!!ERROR!!";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@: %s:%d %@", levelName, function, line, message];
}

#pragma mark - Log

+ (void)logWithLevel:(NSUInteger)level tag:(NSString *)tag file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)message, ...
{
    va_list args;
    va_start(args, message);
    
    [self logWithLevel:level tag:tag file:file function:function line:line format:message args:args];
    
    va_end(args);
}

+ (void)logWithLevel:(NSUInteger)level tag:(NSString *)tag file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format args:(va_list)argList
{
    // ignored or lower levels are skipped
    if (CBTimberLogLevelIgnore == CBTLOG_LEVEL || level < CBTLOG_LEVEL)
        return;
    
    if (![self canLogWithTag:tag function:function])
        return;
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:argList];
    NSString *logMessage = [self logMessageStringUsingOptionsWithMessage:message
                                                                   level:level
                                                                    file:file
                                                                function:function
                                                                    line:line];
    CBTLogMessage(logMessage);
}

@end
