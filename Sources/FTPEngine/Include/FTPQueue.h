//
//  FTPQueue.h
//

#import <Foundation/Foundation.h>

@interface FTPQueue : NSObject

- (void)enqueue:(id)object;
- (id)dequeue;
- (BOOL)removeObject:(id)object;
- (NSArray *)allItems;
- (NSUInteger)count;
- (void)clear;

@end
