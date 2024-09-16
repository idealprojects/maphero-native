#import "NSCompoundPredicate+MHAdditions.h"

#import "MHStyleValue_Private.h"

#import "NSPredicate+MHPrivateAdditions.h"
#import "NSExpression+MHPrivateAdditions.h"
#import "MHLoggingConfiguration_Private.h"

#include <mbgl/style/conversion/property_value.hpp>

@implementation NSCompoundPredicate (MHAdditions)

- (std::vector<mbgl::style::Filter>)mgl_subfilters
{
    std::vector<mbgl::style::Filter>filters;
    for (NSPredicate *predicate in self.subpredicates) {
        filters.push_back(predicate.mgl_filter);
    }
    return filters;
}

@end

@implementation NSCompoundPredicate (MHExpressionAdditions)

- (id)mgl_jsonExpressionObject {
    switch (self.compoundPredicateType) {
        case NSNotPredicateType: {
            MHAssert(self.subpredicates.count <= 1, @"NOT predicate cannot have multiple subpredicates.");
            NSPredicate *subpredicate = self.subpredicates.firstObject;
            return @[@"!", subpredicate.mgl_jsonExpressionObject];
        }
            
        case NSAndPredicateType: {
            NSArray *subarrays = [self.subpredicates valueForKeyPath:@"mgl_jsonExpressionObject"];
            return [@[@"all"] arrayByAddingObjectsFromArray:subarrays];
        }
            
        case NSOrPredicateType: {
            NSArray *subarrays = [self.subpredicates valueForKeyPath:@"mgl_jsonExpressionObject"];
            return [@[@"any"] arrayByAddingObjectsFromArray:subarrays];
        }
    }
    
    [NSException raise:@"Compound predicate type not handled"
                format:@""];
    return nil;
}

@end
