//
//  FTPListingRequest.m
//

#import "FTPListingRequest.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface FTPListingRequest ()

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation FTPListingRequest

@synthesize filesInfo = _filesInfo;
@synthesize receivedData = _receivedData;

- (BOOL)fileExists:(NSString *)fileNamePath
{
    NSString *fileName = [[fileNamePath lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    for (NSDictionary *file in self.filesInfo) {
        NSString *name = [file objectForKey:(id)kCFFTPResourceName];
        if ([fileName isEqualToString:name]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)path
{
    // the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    NSString *directoryPath = [super path];
    if (![directoryPath hasSuffix: @"/"]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

- (void)start
{
    self.maximumSize = LONG_MAX;
    
    // open the read stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openRead:self];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    NSData *data;
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
			self.filesInfo = [NSMutableArray array];
            self.didOpenStream = YES;
            self.receivedData = [NSMutableData data];
            break;
        }
            
        case NSStreamEventHasBytesAvailable: {
            data = [self.streamInfo read:self];
            
            if (data) {
                [self.receivedData appendData:data];
            }
            else {
                [self.streamInfo streamError:self errorCode:kGRFTPClientCantReadStream];
            }
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        break;
            
        case NSStreamEventErrorOccurred: {
            [self.streamInfo streamError:self errorCode:[FTPError errorCodeWithError:[theStream streamError]]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            NSUInteger  offset = 0;
            CFIndex     parsedBytes;
            uint8_t *bytes = (uint8_t *)[self.receivedData bytes];
            NSUInteger totalbytes = [self.receivedData length];
            
            do {
                CFDictionaryRef listingEntity = NULL;
                parsedBytes = CFFTPCreateParsedResourceListing(NULL, &bytes[offset], totalbytes - offset, &listingEntity);
                if (parsedBytes > 0) {
                    if (listingEntity != NULL) {
                        self.filesInfo = [self.filesInfo arrayByAddingObject:(__bridge_transfer NSDictionary *)listingEntity];
                    }
                    offset += parsedBytes;
                }
            } while (parsedBytes > 0);
            
            [self.streamInfo streamComplete:self];
            break;
        }
        
        default:
            break;
    }
}

@end

#pragma clang diagnostic pop
