//
//  FTPListingRequest.h
//

#import "FTPRequest.h"

@interface FTPListingRequest : FTPRequest

@property NSArray *filesInfo;

- (BOOL)fileExists:(NSString *)fileNamePath;

@end
