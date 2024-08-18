//
//  FTPQueue.m
//
//

#import "FTPQueue.h"

@interface FTPQueue ()

@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation FTPQueue

- (instancetype)init
{
    self = [super init];
	if (self) {
		_items = [[NSMutableArray alloc] init];
		_count = 0;
	}
	return self;
}

- (void)enqueue:(id)object
{
	[self.items addObject:object];
	self.count = [self.items count];
}

- (id)dequeue
{
	id obj = nil;
	
    if ([self.items count]) {
		obj = self.items[0];
		[self.items removeObjectAtIndex:0];
	}
    
    self.count = [self.items count];
    return obj;
}

- (BOOL)removeObject:(id)object
{
    if ([self.items containsObject:object]) {
        [self.items removeObject:object];
        return YES;
    }
    
    return NO;
}

- (NSArray *)allItems
{
    return self.items;
}

- (void)clear
{
	[self.items removeAllObjects];
	self.count = 0;
}

@end
