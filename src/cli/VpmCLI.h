#import "../macros.h"

#define VpmServerID VPM_ID( CLIServer )

@protocol VpmCLI

- (void)loadFiles:(NSArray *)files;

@end
