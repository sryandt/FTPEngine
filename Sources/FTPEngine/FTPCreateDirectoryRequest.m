//
//  FTPCreateDirectoryRequest.m
//

#import "FTPCreateDirectoryRequest.h"
#import "FTPListingRequest.h"

@interface FTPCreateDirectoryRequest () <FTPRequestDelegate, FTPRequestDataSource>

@property FTPListingRequest *listrequest;

@end

@implementation FTPCreateDirectoryRequest

@synthesize listrequest;

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
    if ([self hostnameForRequest:self] == nil) {
        self.error = [[FTPError alloc] init];
        self.error.errorCode = kGRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    // we first list the directory to see if our folder is up already
    self.listrequest = [[FTPListingRequest alloc] initWithDelegate:self datasource:self];
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    [self.listrequest start];
}

#pragma mark - FTPRequestDelegate

- (void)requestCompleted:(FTPRequest *)request
{
    NSString *directoryName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    if ([self.listrequest fileExists:directoryName]) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientCantOverwriteDirectory];
    }
    else {
        // open the write stream and check for errors calling delegate methods
        // if things fail. This encapsulates the streamInfo object and cleans up our code.
        [self.streamInfo openWrite:self];
    }
}


- (void)requestFailed:(FTPRequest *)request
{
    [self.delegate requestFailed:request];
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    return NO;
}

#pragma mark - FTPRequestDataSource

- (NSString *)hostnameForRequest:(id<FTPRequestProtocol>)request
{
    return [self.dataSource hostnameForRequest:request];
}

- (NSString *)usernameForRequest:(id<FTPRequestProtocol>)request
{
    return [self.dataSource usernameForRequest:request];
}

- (NSString *)passwordForRequest:(id<FTPRequestProtocol>)request
{
    return [self.dataSource passwordForRequest:request];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        // XCode whines about this missing - which is why it is here
        case NSStreamEventNone:
        case NSStreamEventHasBytesAvailable:
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
            
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
            break;
        }

        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:[FTPError errorCodeWithError:[theStream streamError]]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
            [self.streamInfo streamComplete:self];
            break;
        }
            
        default:
            break;
    }
}

@end
