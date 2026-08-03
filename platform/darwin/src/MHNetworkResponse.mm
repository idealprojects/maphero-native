#import <Foundation/Foundation.h>
#import "MHNetworkResponse.h"

@implementation MHNetworkResponse

+(MHNetworkResponse *)responseWithData:(NSData *)data
                         urlResponse:(NSURLResponse *)response
                               error:(NSError *)error {

    MHNetworkResponse *tempResult = [[MHNetworkResponse alloc] init];
    tempResult.data = data;
    tempResult.response = response;
    tempResult.error = error;
    return tempResult;
}

@end
