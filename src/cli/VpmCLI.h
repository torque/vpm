#import "../macros.h"

#define VpmServerID VPM_ID( CLIServer )

@protocol VpmCLI

- (BOOL)sayHello:(NSString *)message;

@end
