//
//  CBTimber.m
//  Timber
//
//  Created by C. Bess on 12/23/13.
//  Copyright (c) 2013 Christopher Bess. MIT.
//

#import "CBTimber.h"

NSString *const kCBTimberLogOptionFormatterKey = @"log.formatter";
NSString *const kCBTimberLogOptionUsernameKey = @"log.username";
NSString *const kCBTimberLogOptionTagKey = @"log.tag";
NSString *const kCBTimberLogOptionFunctionNameKey = @"log.function";

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
static NSMutableDictionary *gLogMachines = nil;
static id<CBTimberLogFormatter> gLogFormatter = nil;
static BOOL gDefaultLogMachineEnabled = YES;
static NSUInteger gLogLevel = CBTimberLogLevelVerbose;

@implementation CBTimber

+ (void)initialize
{
    gLogMachines = [NSMutableDictionary new];
}

#pragma mark - Log Machines

+ (void)addLogMachine:(id<CBTimberLogMachine>)machine
{
    NSString *identifier = [machine identifier];
    if (gLogMachines[identifier])
        return;
    
    if ([machine respondsToSelector:@selector(didAddLogMachine)])
        [machine didAddLogMachine];
    
    gLogMachines[identifier] = machine;
}

+ (void)removeLogMachine:(id<CBTimberLogMachine>)machine
{
    if ([machine respondsToSelector:@selector(didRemoveLogMachine)])
        [machine didRemoveLogMachine];
    
    [gLogMachines removeObjectForKey:[machine identifier]];
}

+ (void)removeLogMachineWithIdentifier:(NSString *)identifier
{
    id<CBTimberLogMachine> machine = gLogMachines[identifier];
    [self removeLogMachine:machine];
}

#pragma mark - Config

+ (void)setLogOptions:(NSDictionary *)options
{
    NSString *username = options[kCBTimberLogOptionUsernameKey];
    
    if (options[kCBTimberLogOptionTagKey])
    {
        [self setLogTag:options[kCBTimberLogOptionTagKey] forUsername:username];
    }
    
    if (options[kCBTimberLogOptionFunctionNameKey])
    {
        [self setLogFunctionName:options[kCBTimberLogOptionFunctionNameKey] forUsername:username];
    }
    
    id formatter = options[kCBTimberLogOptionFormatterKey];
    if (formatter)
    {
        if (formatter != [NSNull null])
            gLogFormatter = formatter;
        else
            gLogFormatter = nil;
    }
}

+ (BOOL)defaultLogMachineEnabled
{
    return gDefaultLogMachineEnabled;
}

+ (void)setDefaultLogMachineEnabled:(BOOL)enabled
{
    gDefaultLogMachineEnabled = enabled;
}

+ (void)setLogRegexWithPattern:(NSString *)pattern forUsername:(NSString *)username block:(void(^)(NSRegularExpression *regex))regexBlock
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

+ (void)setLogLevel:(CBTimberLogLevel)level {
    gLogLevel = level;
}

+ (CBTimberLogLevel)logLevel {
    return gLogLevel;
}

#pragma mark Function filter

+ (NSString *)logFunctionName
{
    return gLogFunctionNameRegex.pattern;
}

+ (void)setLogFunctionName:(NSString *)functionName forUsername:(NSString *)username
{
    [self setLogRegexWithPattern:functionName forUsername:username block:^(NSRegularExpression *regex) {
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
    [self setLogRegexWithPattern:tag forUsername:username block:^(NSRegularExpression *regex) {
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

+ (NSString *)nameForLogLevel:(CBTimberLogLevel)level
{
    NSString *levelName = [NSString string];
    switch (level)
    {
        case CBTimberLogLevelVerbose:
            levelName = @"verbose";
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
    
    return levelName;
}

+ (BOOL)canLogWithTag:(NSString *)tag
{
    if (!gLogTagRegex)
        return YES;
    
    if ([gLogTagRegex numberOfMatchesInString:tag options:0 range:NSMakeRange(0, tag.length)])
        return YES;
    
    return NO;
}

+ (BOOL)canLogWithFunction:(NSString *)name
{
    if (!gLogFunctionNameRegex)
        return YES;
    
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

+ (NSString *)logMessageStringUsingOptionsWithMessage:(NSString *)message tag:(NSString *)tag level:(NSUInteger)level file:(const char *)file function:(const char *)function line:(int)line
{
    if (gLogFormatter)
    {
        // use provided formatter and skip the default one
        return [gLogFormatter logMessageStringWithMessage:message
                                                      tag:tag
                                                    level:level
                                                     file:file
                                                 function:function
                                                     line:line];
    }
    
    NSString *levelName = [self nameForLogLevel:level];
    return [NSString stringWithFormat:@"%@: %s:%d %@", levelName, function, line, message];
}

#pragma mark - Log

+ (void)runLogMachinesWithLogMessage:(NSString *)message tag:(NSString *)tag level:(NSUInteger)level file:(const char *)file function:(const char *)function line:(int)line
{
    NSString *logMessage = [self logMessageStringUsingOptionsWithMessage:message
                                                                     tag:tag
                                                                   level:level
                                                                    file:file
                                                                function:function
                                                                    line:line];
    BOOL skipDefaultLogMachine = NO;
    NSArray *logMachines = [gLogMachines allValues];
    if (logMachines.count)
    {
        NSString *functionName = [NSString stringWithUTF8String:function];
        
        // each log machine gets the log data
        for (id<CBTimberLogMachine> machine in logMachines)
        {
            if ([machine canLogWithTag:tag functionName:functionName])
            {
                [machine logWithMessage:message level:level tag:tag file:file function:function line:line];
                
                if ([machine skipDefaultLogMachine])
                    skipDefaultLogMachine = YES;
            }
        }
    }
    
    if ([self defaultLogMachineEnabled] && !skipDefaultLogMachine)
        CBTLogMessage(logMessage);
}

+ (void)logWithLevel:(NSUInteger)level tag:(NSString *)tag file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)message, ...
{
    va_list args;
    va_start(args, message);
    
    [self logWithLevel:level tag:tag file:file function:function line:line format:message args:args];
    
    va_end(args);
}

+ (void)logWithLevel:(NSUInteger)level tag:(NSString *)tag file:(const char *)file function:(const char *)function line:(int)line format:(NSString *)format args:(va_list)args
{
    // ignore all, or skip lower levels
    if (CBTimberLogLevelIgnore == gLogLevel || level < gLogLevel)
        return;
    
    if (![self canLogWithTag:tag function:function])
        return;
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    
    [self runLogMachinesWithLogMessage:message tag:tag level:level file:file function:function line:line];
}

#pragma mark - Instance

- (id)init
{
    return nil;
}

@end
