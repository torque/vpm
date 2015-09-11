#import <Cocoa/Cocoa.h>
#import "cli/VpmCLI.h"

@class VpmMpvController;

@interface VpmCLIServer : NSObject <VpmCLI>

@property(nonatomic, strong) NSConnection *server;
@property(nonatomic, strong) VpmMpvController *controller;

- (instancetype)initWithController:(VpmMpvController *)controller;

@end
