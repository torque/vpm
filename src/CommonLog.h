#import <CocoaLumberjack/CocoaLumberjack.h>

// DDLogLevelError
// DDLogLevelWarning
// DDLogLevelInfo
// DDLogLevelDebug
// DDLogLevelVerbose
#if defined(VPM_LOGLEVELOVERRIDE)
	const static DDLogLevel ddLogLevel = VPM_LOGLEVELOVERRIDE;
#else
	#if defined(DEBUG)
		const static DDLogLevel ddLogLevel = DDLogLevelVerbose;
	#else
		const static DDLogLevel ddLogLevel = DDLogLevelWarning;
	#endif
#endif
