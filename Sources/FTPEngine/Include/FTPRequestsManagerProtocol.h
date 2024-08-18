//
//  FTPRequestsManagerProtocol.h
//
//  Created by Alberto De Bortoli on 17/06/2013.
//

#import <Foundation/Foundation.h>

@protocol FTPRequestProtocol;
@protocol FTPDataExchangeRequestProtocol;
@protocol FTPRequestsManagerProtocol;

/** The delegate of a FTPRequestsManager object should adopt the FTPRequestsManagerDelegate protocol. */

@protocol FTPRequestsManagerDelegate <NSObject>

@optional

/**
 @brief Called to notify the delegate that a given request has been scheduled.
 @param requestsManager The requests manager.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didScheduleRequest:(id<FTPRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given listing request completed.
 @param requestsManager The requests manager.
 @param request The request.
 @param listing An array containing the content of a given directory, a list of string file/directory names.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<FTPRequestProtocol>)request listing:(NSArray *)listing;

/**
 @brief Called to notify the delegate that a given listing request completed.
 @param requestsManager The requests manager.
 @param request The request.
 @param listing An array containing the content of a given directory, a list of file/directory dictionaries.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<FTPRequestProtocol>)request listingDetails:(NSArray *)listing;

/**
 @brief Called to notify the delegate that a given create directory request completed.
 @param requestsManager The requests manager.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteCreateDirectoryRequest:(id<FTPRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given generic delete request completed.
 @param requestsManager The requests manager.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<FTPRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given request completed some progress.
 @param requestsManager The requests manager.
 @param percent The percent of the progress reached.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<FTPRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given upload request completed.
 @param requestsManager The requests manager.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<FTPDataExchangeRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given downlaod request completed.
 @param requestsManager The requests manager.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<FTPDataExchangeRequestProtocol>)request;

/**
 @brief Called to notify the delegate that a given download request failed writing the file locally.
 @param requestsManager The requests manager.
 @param path The local path that fail writing to.
 @param request The request.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<FTPDataExchangeRequestProtocol>)request error:(NSError *)error;

/**
 @brief Called to notify the delegate that a given request failed.
 @param requestsManager The requests manager.
 @param request The request.
 @param error The error reporterd.
 */
- (void)requestsManager:(id<FTPRequestsManagerProtocol>)requestsManager didFailRequest:(id<FTPRequestProtocol>)request withError:(NSError *)error;

/**
 @brief Called to notify the delegate that the queue has been emptied.
 @param requestsManager The requests manager.
 */
- (void)requestsManagerDidCompleteQueue:(id<FTPRequestsManagerProtocol>)requestsManager;

@end

/** Protocol interface for object FTPRequestsManager objects. */

@protocol FTPRequestsManagerProtocol <NSObject>

/**
 The hostname of the FTP service.
 */
@property (nonatomic, copy) NSString *hostname;

/** 
 @brief Add a request to the manager for listing a directory at a given path.
 @param path The path of the directory to list.
 @return The created request, conforming to FTPRequestProtocol.
 */
- (id<FTPRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)path;

/**
 @brief Add a request to the manager for creating a directory at a given path.
 @param path The path of the directory to create.
 @return The created request, conforming to FTPRequestProtocol.
 */
- (id<FTPRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)path;

/**
 @brief Add a request to the manager for deleting a file at a given path.
 @param filePath The path of the file to delete.
 @return The created request, conforming to FTPRequestProtocol.
 */
- (id<FTPRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filePath;

/**
 @brief Add a request to the manager for deleting a directory at a given path.
 @param path The path of the directory to delete.
 @return The created request, conforming to FTPRequestProtocol.
 */
- (id<FTPRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)path;

/**
 @brief Add a request to the manager for downloading a file at a given relative remote path to a given local absolute path.
 @param remotePath The remote relative path of the file to download.
 @param localPath The local absolute path to use for downloading the remote file.
 @return The created request, conforming to FTPDataExchangeRequestProtocol.
 */
- (id<FTPDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath;

/**
 @brief Add a request to the manager for uploading a file from a given local absolute path to a given relative remote path.
 @param localPath The local absolute path of the file to upload.
 @param remotePath The remote relative path to use for uploading the local file.
 @return The created request, conforming to FTPDataExchangeRequestProtocol.
 */
- (id<FTPDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath;

/**
 @brief Start the manager to process the requests.
 */
- (void)startProcessingRequests;

/**
 @brief Stop the manager and cancel all the pending requests.
 */
- (void)stopAndCancelAllRequests;

/**
 @brief Ask the manager to cancel a specific pending request.
 @param request The request to cancel.
 @return YES if the operation succeeded, NO otherwise.
 */
- (BOOL)cancelRequest:(id<FTPRequestProtocol>)request;

/**
 @brief Returns the number of requests currently in the queue.
 */
- (NSUInteger)remainingRequests;

@end
