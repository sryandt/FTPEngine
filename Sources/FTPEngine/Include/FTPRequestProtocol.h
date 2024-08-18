//
//  FTPRequestDelegate.h
//

#import <Foundation/Foundation.h>

@class FTPRequest;
@class FTPError;
@class FTPStreamInfo;

@protocol FTPRequestProtocol <NSObject>

@property (nonatomic, assign) BOOL passiveMode;
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) FTPError *error;
@property (nonatomic, strong) FTPStreamInfo *streamInfo;

@property (nonatomic, assign) float maximumSize;
@property (nonatomic, assign) float percentCompleted;

- (NSURL *)fullURL;
- (NSURL *)fullURLWithEscape;
- (void)start;
- (void)cancelRequest;

@end

@protocol FTPDataExchangeRequestProtocol <FTPRequestProtocol>

@property (nonatomic, copy) NSString *localFilePath;
@property (nonatomic, readonly) NSString *fullRemotePath;

@end

@protocol FTPRequestDelegate <NSObject>

@required
- (void)requestCompleted:(id<FTPRequestProtocol>)request;
- (void)requestFailed:(id<FTPRequestProtocol>)request;

@optional
- (void)percentCompleted:(float)percent forRequest:(id<FTPRequestProtocol>)request;
- (void)dataAvailable:(NSData *)data forRequest:(id<FTPDataExchangeRequestProtocol>)request;
- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<FTPDataExchangeRequestProtocol>)request;

@end

@protocol FTPRequestDataSource <NSObject>

@required
- (NSString *)hostnameForRequest:(id<FTPRequestProtocol>)request;
- (NSString *)usernameForRequest:(id<FTPRequestProtocol>)request;
- (NSString *)passwordForRequest:(id<FTPRequestProtocol>)request;

@optional
- (long)dataSizeForUploadRequest:(id<FTPDataExchangeRequestProtocol>)request;
- (NSData *)dataForUploadRequest:(id<FTPDataExchangeRequestProtocol>)request;

@end
