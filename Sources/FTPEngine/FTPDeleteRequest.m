//
//  FTPDeleteRequest.m
//

#import "FTPDeleteRequest.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FTPDeleteRequest

- (NSString *)path
{
    NSString *lastCharacter = [_path substringFromIndex:[_path length] - 1];
    BOOL isDirectory = ([lastCharacter isEqualToString:@"/"]);
    
    if (!isDirectory) {
        return [super path];
    }
    
    NSString *directoryPath = [super path];
    if (![directoryPath isEqualToString:@""]) {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    
    return directoryPath;
}

- (void)start
{
    SInt32 errorcode;
    
    if ([self.dataSource hostnameForRequest:self] == nil) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientHostnameIsNil];
        return;
    }
    
    if (CFURLDestroyResource(( __bridge CFURLRef) self.fullURLWithEscape, &errorcode)) {
        // successful
        [self.streamInfo streamComplete:self];
    }
    
    else {
        // unsuccessful        
        [self.streamInfo streamError:self errorCode:kGRFTPClientCantDeleteFileOrDirectory];
    }
}

@end

#pragma clang diagnostic pop
