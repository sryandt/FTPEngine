//
//  FTPUploadRequest.m
//

#import "FTPUploadRequest.h"
#import "FTPListingRequest.h"

@interface FTPUploadRequest () <FTPRequestDelegate, FTPRequestDataSource>

@property (nonatomic, assign) long bytesIndex;
@property (nonatomic, assign) long bytesRemaining;
@property (nonatomic, strong) NSData *sentData;
@property (nonatomic, strong) FTPListingRequest *listingRequest;

@end

@implementation FTPUploadRequest

@synthesize localFilePath = _localFilePath;
@synthesize fullRemotePath = _fullRemotePath;

- (void)start
{
    self.maximumSize = LONG_MAX;
    self.bytesIndex = 0;
    self.bytesRemaining = 0;
    
    if ([self.dataSource respondsToSelector:@selector(dataForUploadRequest:)] == NO) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientMissingRequestDataAvailable];
        return;
    }
    
    // we first list the directory to see if our folder is up on the server
    self.listingRequest = [[FTPListingRequest alloc] initWithDelegate:self datasource:self];
	self.listingRequest.passiveMode = self.passiveMode;
    self.listingRequest.path = [self.path stringByDeletingLastPathComponent];
    [self.listingRequest start];
}

#pragma mark - FTPRequestDelegate

- (void)requestCompleted:(FTPRequest *)request
{
    NSString *fileName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    if ([self.listingRequest fileExists:fileName]) {
        if ([self.delegate shouldOverwriteFile:self.path forRequest:self] == NO) {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:kGRFTPClientFileAlreadyExists];
            return;
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(dataSizeForUploadRequest:)]) {
        self.maximumSize = [self.dataSource dataSizeForUploadRequest:self];
    }
    
    // open the write stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openWrite:self];
}

- (void)requestFailed:(FTPRequest *)request
{
    [self.delegate requestFailed:request];
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    return [self.delegate shouldOverwriteFile:filePath forRequest:request];
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
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
            self.streamInfo.bytesTotal = 0;
            break;
        }
            
        case NSStreamEventHasBytesAvailable:
        break;
            
        case NSStreamEventHasSpaceAvailable: {
            if (self.bytesRemaining == 0) {
                if ([self.dataSource respondsToSelector:@selector(dataForUploadRequest:)]) {
                    self.sentData = [self.dataSource dataForUploadRequest:self];
                }
                else {
                    return;
                }
                self.bytesRemaining = [_sentData length];
                self.bytesIndex = 0;
                
                // we are done
                if (self.sentData == nil) {
                    [self.streamInfo streamComplete:self]; // perform callbacks and close out streams
                    return;
                }
            }
            
            NSUInteger nextPackageLength = MIN(kGRDefaultBufferSize, self.bytesRemaining);
            NSRange range = NSMakeRange(self.bytesIndex, nextPackageLength);
            NSData *packetToSend = [self.sentData subdataWithRange: range];

            [self.streamInfo write:self data: packetToSend];
            
            self.bytesIndex += self.streamInfo.bytesThisIteration;
            self.bytesRemaining -= self.streamInfo.bytesThisIteration;
            break;
        }
            
        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:[FTPError errorCodeWithError:[theStream streamError]]];
            break;
        }
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:kGRFTPServerAbortedTransfer];
            break;
        }
        
        default:
            break;
    }
}

- (NSString *)fullRemotePath
{
    return [[self fullURL] absoluteString];
}

@end
