//
//  FTPRequest.h
//

#import "FTPRequestProtocol.h"
#import "FTPError.h"
#import "FTPStreamInfo.h"

@class FTPRequest;
@class FTPDownloadRequest;
@class FTPUploadRequest;

@interface FTPRequest : NSObject <NSStreamDelegate, FTPRequestProtocol>
{
    NSString *_path;
}

@property (nonatomic, weak) id <FTPRequestDelegate> delegate;
@property (nonatomic, weak) id <FTPRequestDataSource> dataSource;

@property (nonatomic, readonly) long bytesSent;                 // will have bytes from the last FTP call
@property (nonatomic, readonly) long totalBytesSent;            // will have bytes total sent
@property (nonatomic, assign) BOOL didOpenStream;               // whether the stream opened or not
@property (nonatomic, assign) BOOL cancelDoesNotCallDelegate;   // cancel closes stream without calling delegate

- (instancetype)initWithDelegate:(id<FTPRequestDelegate>)aDelegate datasource:(id<FTPRequestDataSource>)aDatasource;

@end
