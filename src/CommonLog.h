#import <CocoaLumberjack/CocoaLumberjack.h>

// DDLogLevelError
// DDLogLevelWarning
// DDLogLevelInfo
// DDLogLevelDebug
// DDLogLevelVerbose
#if defined(DEBUG)
	const static DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
	const static DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
