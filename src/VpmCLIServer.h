#import <Cocoa/Cocoa.h>
#import "cli/VpmCLI.h"

@interface VpmCLIServer : NSObject <VpmCLI>

@property(nonatomic, strong) NSConnection *server;

@end
