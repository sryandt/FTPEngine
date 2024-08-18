//
//  FTPRequestsManager.h
//
//  Created by Alberto De Bortoli on 14/06/2013.
//

#import <Foundation/Foundation.h>

#import "FTPRequestsManagerProtocol.h"

/**
 Instances of this class manage a queue of requests against an FTP server.
 The different request types are:
 
  * list directory
  * create directory
  * delete directory
  * delete file
  * upload file
  * download file
 
 As soon as the requests are submitted to the FTPRequestsManager, they are queued in a FIFO queue.
 The FTP Manager must be started with the startProcessingRequests method and can be shut down with the stopAndCancelAllRequests method.
 When processed, the requests are executed one at a time (max concurrency = 1).
 When no more requests are in the queue the FTPRequestsManager automatically shut down.
*/
@interface FTPRequestsManager : NSObject <FTPRequestsManagerProtocol>

/**
 Reference to the delegate object
 */
@property (nonatomic, weak) id<FTPRequestsManagerDelegate> delegate;

/**
 @brief Initialize a FTPRequestsManager object with given hostname, username and password.
 @param hostname The hostname of the FTP service to connect to.
 @param username The username to use for connecting to the FTP service.
 @param password The password to use for connecting to the FTP service.
 @return A FTPRequestsManager object.
 */
- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password;

@end
