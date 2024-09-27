//
//  FTPRequestsManager.m
//

#import "FTPRequestsManager.h"

#import "FTPListingRequest.h"
#import "FTPCreateDirectoryRequest.h"
#import "FTPUploadRequest.h"
#import "FTPDownloadRequest.h"
#import "FTPDeleteRequest.h"
                                
#import "FTPQueue.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface FTPRequestsManager () <FTPRequestDelegate, FTPRequestDataSource>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) NSMutableData *currentDownloadData;
@property (nonatomic, strong) NSData *currentUploadData;
@property (nonatomic, strong) FTPQueue *requestQueue;
@property (nonatomic, strong) FTPRequest *currentRequest;
@property (nonatomic, assign) BOOL delegateRespondsToPercentProgress;
@property (nonatomic, assign) BOOL isRunning;

- (id<FTPRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath;
- (id<FTPDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath;
- (void)_enqueueRequest:(id<FTPRequestProtocol>)request;
- (void)_processNextRequest;

@end

@implementation FTPRequestsManager

@synthesize hostname = _hostname;
@synthesize delegate = _delegate;

#pragma mark - Dealloc and Initialization

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password
{
    NSAssert([hostname length], @"hostname must not be nil");
    
    self = [super init];
    if (self) {
        _hostname = hostname;
        _username = username;
        _password = password;
        _requestQueue = [[FTPQueue alloc] init];
        _isRunning = NO;
        _delegateRespondsToPercentProgress = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopAndCancelAllRequests];
}

#pragma mark - Setters

- (void)setDelegate:(id<FTPRequestsManagerDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        _delegateRespondsToPercentProgress = [_delegate respondsToSelector:@selector(requestsManager:didCompletePercent:forRequest:)];
    }
}

#pragma mark - Public Methods

- (void)startProcessingRequests
{
    if (_isRunning == NO) {
        _isRunning = YES;
        [self _processNextRequest];
    }
}

- (void)stopAndCancelAllRequests
{
    [self.requestQueue clear];
    self.currentRequest.cancelDoesNotCallDelegate = YES;
    [self.currentRequest cancelRequest];
    self.currentRequest = nil;
    _isRunning = NO;
}

- (BOOL)cancelRequest:(FTPRequest *)request
{
    return [self.requestQueue removeObject:request];
}

- (NSUInteger)remainingRequests
{
    return [self.requestQueue count];
}

#pragma mark - FTP Actions

- (id<FTPRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)path
{
    return [self _addRequestOfType:[FTPListingRequest class] withPath:path];
}

- (id<FTPRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)path
{
    return [self _addRequestOfType:[FTPCreateDirectoryRequest class] withPath:path];
}

- (id<FTPRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[FTPDeleteRequest class] withPath:filePath];
}

- (id<FTPRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)path
{
    return [self _addRequestOfType:[FTPDeleteRequest class] withPath:path];
}

- (id<FTPDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath
{
    return [self _addDataExchangeRequestOfType:[FTPDownloadRequest class] withLocalPath:localPath remotePath:remotePath];
}

- (id<FTPDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath
{
    return [self _addDataExchangeRequestOfType:[FTPUploadRequest class] withLocalPath:localPath remotePath:remotePath];
}

#pragma mark - FTPRequestDelegate required

- (void)requestCompleted:(FTPRequest *)request
{
    // listing request
    if ([request isKindOfClass:[FTPListingRequest class]]) {
		 NSArray *dicts = ((FTPListingRequest *)request).filesInfo;
		 
		 if (dicts == nil) { dicts = @[]; }
		 
        NSMutableArray *listing = [NSMutableArray array];
        for (NSDictionary *file in dicts) {
            [listing addObject:[file objectForKey:(id)kCFFTPResourceName]];
        }
		 
		 if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteListingRequest:listingDetails:)]) {
			  [self.delegate requestsManager:self
					 didCompleteListingRequest:((FTPListingRequest *)request)
									listingDetails: dicts];
		 } else if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteListingRequest:listing:)]) {
			  [self.delegate requestsManager:self
					 didCompleteListingRequest:((FTPListingRequest *)request)
											 listing:listing];
		 }
}
    
    // create directory request
    if ([request isKindOfClass:[FTPCreateDirectoryRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteCreateDirectoryRequest:)]) {
            [self.delegate requestsManager:self didCompleteCreateDirectoryRequest:(FTPUploadRequest *)request];
        }
    }

    // delete request
    if ([request isKindOfClass:[FTPDeleteRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteDeleteRequest:)]) {
            [self.delegate requestsManager:self didCompleteDeleteRequest:(FTPUploadRequest *)request];
        }
    }

    // upload request
    if ([request isKindOfClass:[FTPUploadRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteUploadRequest:)]) {
            [self.delegate requestsManager:self didCompleteUploadRequest:(FTPUploadRequest *)request];
        }
        _currentUploadData = nil;
    }
    
    // download request
    else if ([request isKindOfClass:[FTPDownloadRequest class]]) {
        NSError *writeError = nil;
        BOOL writeToFileSucceeded = [_currentDownloadData writeToFile:((FTPDownloadRequest *)request).localFilePath
                                                              options:NSDataWritingAtomic
                                                                error:&writeError];
        
        if (writeToFileSucceeded && !writeError) {
            if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteDownloadRequest:)]) {
                [self.delegate requestsManager:self didCompleteDownloadRequest:(FTPDownloadRequest *)request];
            }
        }
        else {
            if ([self.delegate respondsToSelector:@selector(requestsManager:didFailWritingFileAtPath:forRequest:error:)]) {
                [self.delegate requestsManager:self
                      didFailWritingFileAtPath:((FTPDownloadRequest *)request).localFilePath
                                    forRequest:(FTPDownloadRequest *)request
                                         error:writeError];
            }
        }
        _currentDownloadData = nil;
    }
    
    [self _processNextRequest];
}

- (void)requestFailed:(FTPRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(requestsManager:didFailRequest:withError:)]) {
        NSError *error = [NSError errorWithDomain:@"com.detectiontek.ftpengine" code:-1000 userInfo:@{@"message": request.error.message}];
        [self.delegate requestsManager:self didFailRequest:request withError:error];
    }
    
    [self _processNextRequest];
}

#pragma mark - FTPRequestDelegate optional

- (void)percentCompleted:(float)percent forRequest:(id<FTPRequestProtocol>)request
{
    if (_delegateRespondsToPercentProgress) {
        [self.delegate requestsManager:self didCompletePercent:percent forRequest:request];
    }
}

- (void)dataAvailable:(NSData *)data forRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    [_currentDownloadData appendData:data];
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    // called only with FTPUploadRequest requests
    return YES;
}

#pragma mark - FTPRequestDataSource

- (NSString *)hostnameForRequest:(id<FTPRequestProtocol>)request
{
    return self.hostname;
}

- (NSString *)usernameForRequest:(id<FTPRequestProtocol>)request
{
    return self.username;
}

- (NSString *)passwordForRequest:(id<FTPRequestProtocol>)request
{
    return self.password;
}

- (long)dataSizeForUploadRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    return [_currentUploadData length];
}

- (NSData *)dataForUploadRequest:(id<FTPDataExchangeRequestProtocol>)request
{
    NSData *temp = _currentUploadData;
    _currentUploadData = nil; // next time will return nil;
    return temp;
}

#pragma mark - Private Methods

- (id<FTPRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath
{
    id<FTPRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = filePath;
    
    [self _enqueueRequest:request];
    return request;
}

- (id<FTPDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath
{
    id<FTPDataExchangeRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = remotePath;
    request.localFilePath = localPath;
    
    [self _enqueueRequest:request];
    return request;
}

- (void)_enqueueRequest:(id<FTPRequestProtocol>)request
{
    [self.requestQueue enqueue:request];
}

- (void)_processNextRequest
{
    self.currentRequest = [self.requestQueue dequeue];
    
    if (self.currentRequest == nil) {
        [self stopAndCancelAllRequests];
        
        if ([self.delegate respondsToSelector:@selector(requestsManagerDidCompleteQueue:)]) {
            [self.delegate requestsManagerDidCompleteQueue:self];
        }
        
        return;
    }
    
    if ([self.currentRequest isKindOfClass:[FTPDownloadRequest class]]) {
        _currentDownloadData = [NSMutableData dataWithCapacity:4096];
    }
    if ([self.currentRequest isKindOfClass:[FTPUploadRequest class]]) {
        NSString *localFilepath = ((FTPUploadRequest *)self.currentRequest).localFilePath;
        _currentUploadData = [NSData dataWithContentsOfFile:localFilepath];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentRequest start];
    });
    
    if ([self.delegate respondsToSelector:@selector(requestsManager:didScheduleRequest:)]) {
        [self.delegate requestsManager:self didScheduleRequest:self.currentRequest];
    }
}

@end

#pragma clang diagnostic pop
