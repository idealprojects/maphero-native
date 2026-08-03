#import <Foundation/Foundation.h>
#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

MH_EXPORT
@interface MHNetworkResponse : NSObject

@property (retain, nullable) NSError *error;
@property (retain, nullable) NSData *data;
@property (retain, nullable) NSURLResponse *response;

+ (MHNetworkResponse *)responseWithData:(NSData *)data
                             urlResponse:(NSURLResponse *)response
                                   error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
