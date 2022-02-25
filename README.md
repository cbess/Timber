Timber
======

iOS and macOS app logging made easy, for the whole team.

## Install

Cocoapods: `pod 'Timber'`

`#import <Timber/Timber.h>`

## Usage
	
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CBTDebugMark();
	
	[CBTimber setLogTag:@"test" forUsername:@"cbess"];
	//[CBTimber setLogTag:@"test one" forUsername:nil]; // overrides any tags specified by a username
	
    CBTLogDebugt(@"test tag", @"simple test log: %@", @7);
    
    return YES;
}
```

Enable using:  
`-D DEBUG=1` or `-D ENABLE_TIMBER=1`

## Macros

CBTLog(Level, Tag, Message, ...)  
CBTDebugCode(BLOCK)  
CBTDebugMark()

#### Log macros

CBTLogVerbose(MSG, ...)  
CBTLogDebug(MSG, ...)  
CBTLogInfo(MSG, ...)  
CBTLogWarn(MSG, ...)  
CBTLogError(MSG, ...)  
CBTLogDebugError(`NSError`)  

#### Log macros w/ tagging

CBTLogVerboset(TAG, MSG, ...)  
CBTLogDebugt(TAG, MSG, ...)  
CBTLogInfot(TAG, MSG, ...)  
CBTLogWarnt(TAG, MSG, ...)  
CBTLogErrort(TAG, MSG, ...)  

## Notes

See `CBTimber.h` for more details.
