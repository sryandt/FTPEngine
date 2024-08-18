//
//  FTPStreamInfo.h
//

#import "FTPError.h"

#define kGRDefaultBufferSize 32768

@protocol FTPRequestProtocol;

@interface FTPStreamInfo : NSObject

@property (nonatomic, strong) NSOutputStream *writeStream;
@property (nonatomic, strong) NSInputStream *readStream;

@property (nonatomic, assign) long bytesThisIteration;
@property (nonatomic, assign) long bytesTotal;
@property (nonatomic, assign) long timeout;
@property (nonatomic, assign) BOOL cancelRequestFlag;
@property (nonatomic, assign) BOOL cancelDoesNotCallDelegate;

- (void)openRead:(id<FTPRequestProtocol>)request;
- (void)openWrite:(id<FTPRequestProtocol>)request;
- (BOOL)checkCancelRequest:(id<FTPRequestProtocol>)request;
- (NSData *)read:(id<FTPRequestProtocol>)request;
- (BOOL)write:(id<FTPRequestProtocol>)request data:(NSData *)data;
- (void)streamError:(id<FTPRequestProtocol>)request errorCode:(enum FTPErrorCodes)errorCode;
- (void)streamComplete:(id<FTPRequestProtocol>)request;
- (void)close:(id<FTPRequestProtocol>)request;

@end
