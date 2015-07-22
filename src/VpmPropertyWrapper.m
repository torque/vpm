#import "VpmPropertyWrapper.h"
#import "VpmWindow.h"
#import "VpmMpvController.h"

#pragma mark - PropertyWrapperBackingObject

@interface PropertyWrapperBackingObject : NSObject
	@property(nonatomic, strong) NSString *value;
	@property(nonatomic, strong) NSMutableArray *callbackArray;
	@property BOOL activeObserver;
	@property NSInteger mpvObservationIndex;
@end

@implementation PropertyWrapperBackingObject

- (instancetype)init {
	if ( self = [super init] ) {
		self.callbackArray = [NSMutableArray new];
		self.activeObserver = NO;
		self.mpvObservationIndex = 0;
	}

	return self;
}

- (instancetype)initWithValue:(NSString *)value {
	if ( self = [self init] )
		self.value = value;

	return self;
}

@end

#pragma mark - VpmPropertyWrapper private category

@interface VpmPropertyWrapper()

@property NSInteger mpvObservationCount;
@property(strong) ValueChangedCallback javascriptCallback;
@property NSMutableDictionary *backingDictionary;
@property(strong) dispatch_queue_t callbackQueue;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)setUpDefaultCallbacks;
- (PropertyWrapperBackingObject *)createMpvObserver:(NSString *)name withCallback:(ValueChangedCallback)callback;

@end

#pragma mark - VpmPropertyWrapper implementation

@implementation VpmPropertyWrapper

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	if ( self = [super init] ) {
		self.backingDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
		for ( NSString *key in dictionary )
			self.backingDictionary[key] = [[PropertyWrapperBackingObject alloc] initWithValue:dictionary[key]];
	}

	return self;
}

- (instancetype)initWithMpvController:(VpmMpvController *)controller {
	// All vpm native properties, the ones that aren't backed by mpv properties,
	// are initialized in this dictionary.
	if ( self = [self initWithDictionary:@{
	     	@"fullscreen": ([controller.window styleMask] & NSFullScreenWindowMask)? @"yes": @"no"
	     }]
	) {
		self.controller = controller;
		self.mpvObservationCount = 0;
		self.callbackQueue = dispatch_queue_create( "org.unorg.vpm.PropertyWrapper.cbq", DISPATCH_QUEUE_SERIAL );
		[self setUpDefaultCallbacks];
	}

	return self;
}

- (void)setUpDefaultCallbacks {
	VpmMpvController *controller = self.controller;
	self.javascriptCallback = ^(NSString *name, NSString *value, NSString *oldValue) {
		dispatch_async( dispatch_get_main_queue( ), ^{
			if ( controller )
				[controller.ctx[@"window"][@"signalPropertyChange"] callWithArguments:@[name, value, oldValue]];
		} );
	};

	[self observeProperty:@"fullscreen" withCallback:^(NSString *name, NSString *value, NSString *oldValue) {
		dispatch_async( dispatch_get_main_queue( ), ^{
			if ( controller )
				[controller.window toggleFullScreen:controller];
		} );
	}];
}

- (void)handleMpvPropertyChange:(mpv_event_property*)property {
	switch ( property->format ) {
		case MPV_FORMAT_STRING: {
			const char *val = *(char **)property->data;
			NSString *value = [NSString stringWithCString:val encoding:NSUTF8StringEncoding];
			NSString *name = [NSString stringWithCString:property->name encoding:NSUTF8StringEncoding];
			if ( value )
				self[name] = value;
		}
		default: {}
	}
}

- (void)addJSCallbackForProperty:(NSString *)name {
	[self observeProperty:name withCallback:self.javascriptCallback];
}

- (void)removeJSCallbackForProperty:(NSString *)name {
	[self unobserveProperty:name withCallback:self.javascriptCallback];
}

- (PropertyWrapperBackingObject *)createMpvObserver:(NSString *)name withCallback:(ValueChangedCallback)callback {
	if ( [self.controller observeMpvProperty:name usingIndex:self.mpvObservationCount+1] ) {
		PropertyWrapperBackingObject *obj = [[PropertyWrapperBackingObject alloc] initWithValue:[self.controller getMpvProperty:name]];
		obj.mpvObservationIndex = ++self.mpvObservationCount;
		obj.activeObserver = YES;
		[obj.callbackArray addObject:callback];
		return obj;
	}
	return nil;
}

// lazily fall back to mpv if key doesn't exist in the backing dictionary. If
// the property exists in mpv, its value is returned.
- (NSString *)objectForKeyedSubscript:(NSString*)key {
	PropertyWrapperBackingObject *obj = self.backingDictionary[key];
	// if the property is actively being observed or is not backed by an mpv
	// property, return its value. Otherwise, fall back to mpv.
	if ( obj && ( obj.activeObserver || obj.mpvObservationIndex == 0 ) )
		return obj.value;
	else
		return [self.controller getMpvProperty:key];
}

- (void)setObject:(NSString *)value forKeyedSubscript:(NSString *)key {
	PropertyWrapperBackingObject *obj = self.backingDictionary[key];
	if ( obj != nil ) {
		if ( obj.value != value ) {
			NSString *oldValue = obj.value;
			dispatch_async( self.callbackQueue, ^{
				for ( ValueChangedCallback callback in obj.callbackArray )
					callback( key, value, oldValue );
			} );

			obj.value = value;
			if ( obj.mpvObservationIndex > 0 )
				[self.controller setMpvProperty:key toValue:value];
		}
	} else
		[self.controller setMpvProperty:key toValue:value];
}

- (void)observeProperty:(NSString *)name withCallback:(ValueChangedCallback)callback {
	PropertyWrapperBackingObject *obj = self.backingDictionary[name];
	if ( obj != nil ) {
		if ( !obj.activeObserver && obj.mpvObservationIndex > 0 ) {
			[self.controller observeMpvProperty:name usingIndex:obj.mpvObservationIndex];
		}

		[obj.callbackArray addObject:callback];
		obj.activeObserver = YES;
	} else {
		obj = [self createMpvObserver:name withCallback:callback];
		if ( obj ) {
			self.backingDictionary[name] = obj;
		}
	}
}

- (void)unobserveProperty:(NSString *)name withCallback:(ValueChangedCallback)callback {
	PropertyWrapperBackingObject *obj = self.backingDictionary[name];
	if ( obj != nil )
		[obj.callbackArray removeObjectIdenticalTo:callback];

	if ( [obj.callbackArray count] == 0 ) {
		if ( obj.mpvObservationIndex > 0 )
			[self.controller unobserveMpvProperty:obj.mpvObservationIndex];
		obj.activeObserver = NO;
	}
}

@end
