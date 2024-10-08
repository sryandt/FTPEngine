//
//  FTPRequest.m
//

#import "FTPRequest.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FTPRequest

@synthesize passiveMode = _passiveMode;
@synthesize uuid = _uuid;
@synthesize error = _error;
@synthesize streamInfo = _streamInfo;
@synthesize maximumSize = _maximumSize;
@synthesize percentCompleted = _percentCompleted;
@synthesize delegate = _delegate;
@synthesize didOpenStream = _didOpenStream;
@synthesize path = _path;

- (instancetype)initWithDelegate:(id<FTPRequestDelegate>)aDelegate datasource:(id<FTPRequestDataSource>)aDatasource
{
    self = [super init];
    if (self) {
		_passiveMode = YES;
        _uuid = [[NSUUID UUID] UUIDString];
        _path = nil;
        _streamInfo = [[FTPStreamInfo alloc] init];
        _delegate = aDelegate;
        _dataSource = aDatasource;
    }
    return self;
}

#pragma mark - FTPRequestProtocol

- (NSURL *)fullURL
{
    NSString *hostname = [self.dataSource hostnameForRequest:self];
    NSString *ftpPrefix = @"ftp://";
    if (hostname.length >= 6 && [[hostname substringToIndex:6] isEqualToString:ftpPrefix]) {
        hostname = [hostname substringFromIndex:6];
    }
    NSString *path = [self.path hasPrefix:@"/"] ? [self.path substringFromIndex:1] : self.path;
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@/%@", ftpPrefix, hostname, path];
    return [NSURL URLWithString:fullURLString];
}

- (NSURL *)fullURLWithEscape
{
    NSString *escapedUsername = [self encodeString:[self.dataSource usernameForRequest:self]];
    NSString *escapedPassword = [self encodeString:[self.dataSource passwordForRequest:self]];
    NSString *cred;
    
    if (escapedUsername != nil) {
        if (escapedPassword != nil) {
            cred = [NSString stringWithFormat:@"%@:%@@", escapedUsername, escapedPassword];
        }
        else {
            cred = [NSString stringWithFormat:@"%@@", escapedUsername];
        }
    }
    else {
        cred = @"";
    }
    cred = [cred stringByStandardizingPath];
    
    NSString *hostname = [self.dataSource hostnameForRequest:self];
    NSString *ftpPrefix = @"ftp://";
    if (hostname.length >= 6 && [[hostname substringToIndex:6] isEqualToString:ftpPrefix]) {
        hostname = [hostname substringFromIndex:6];
    }
    NSString *path = [self.path hasPrefix:@"/"] ? [self.path substringFromIndex:1] : self.path;
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@%@/%@", ftpPrefix, cred, hostname, path];
    return [NSURL URLWithString:fullURLString];
}

- (NSString *)path
{
    // we remove all the extra slashes from the directory path, including the last one (if there is one)
    // we also escape it
    NSString *escapedPath = [_path stringByStandardizingPath];
    
    // we need the path to be absolute, if it's not, we *make* it
    if ([escapedPath isAbsolutePath] == NO) {
        escapedPath = [@"/" stringByAppendingString:escapedPath];
    }
    
    // now make sure that we have escaped all special characters
    escapedPath = [self encodeString:escapedPath];
    
    return escapedPath;
}

- (void)setPath:(NSString *)directoryPathLocal
{
    _path = directoryPathLocal;
}

- (NSString *)encodeString:(NSString *)string;
{
    NSString *urlEncoded = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                                 NULL,
                                                                                                 (__bridge CFStringRef) string,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'\"();:@&=+$,?%#[]% ",
                                                                                                 kCFStringEncodingUTF8);
    return urlEncoded;
}  

- (void)start
{
    // override in subclasses
}

- (long)bytesSent
{
    return self.streamInfo.bytesThisIteration;
}

- (long)totalBytesSent
{
    return self.streamInfo.bytesTotal;
}

- (long)timeout
{
    return self.streamInfo.timeout;
}

- (void)setTimeout:(long)timeout
{
    self.streamInfo.timeout = timeout;
}

- (void)cancelRequest
{
    self.streamInfo.cancelRequestFlag = YES;
}

- (BOOL)cancelDoesNotCallDelegate
{
    return self.streamInfo.cancelDoesNotCallDelegate;
}

- (void)setCancelDoesNotCallDelegate:(BOOL)cancelDoesNotCallDelegate
{
    self.streamInfo.cancelDoesNotCallDelegate = cancelDoesNotCallDelegate;
}

@end

#pragma clang diagnostic pop
