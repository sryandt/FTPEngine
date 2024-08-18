//
//  FTPError.h
//

#import <Foundation/Foundation.h>

typedef enum FTPErrorCodes {
    //client errors
    kGRFTPClientHostnameIsNil = 901,
    kGRFTPClientCantOpenStream = 902,
    kGRFTPClientCantWriteStream = 903,
    kGRFTPClientCantReadStream = 904,
    kGRFTPClientSentDataIsNil = 905,
    kGRFTPClientFileAlreadyExists = 907,
    kGRFTPClientCantOverwriteDirectory = 908,
    kGRFTPClientStreamTimedOut = 909,
    kGRFTPClientCantDeleteFileOrDirectory = 910,
    kGRFTPClientMissingRequestDataAvailable = 911,
    
    // 400 FTP errors
    kGRFTPServerAbortedTransfer = 426,
    kGRFTPServerResourceBusy = 450,
    kGRFTPServerCantOpenDataConnection = 425,
    
    // 500 FTP errors
    kGRFTPServerUserNotLoggedIn = 530,
    kGRFTPServerFileNotAvailable = 550,
    kGRFTPServerStorageAllocationExceeded = 552,
    kGRFTPServerIllegalFileName = 553,
    kGRFTPServerUnknownError
} FTPErrorCodes;

@interface FTPError : NSObject

@property (assign) FTPErrorCodes errorCode;
@property (readonly) NSString *message;

+ (FTPErrorCodes)errorCodeWithError:(NSError *)error;

@end
