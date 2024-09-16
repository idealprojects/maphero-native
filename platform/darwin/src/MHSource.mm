#import "MHSource_Private.h"
#import "MHStyle_Private.h"
#import "MHMapView_Private.h"
#import "NSBundle+MHAdditions.h"

#include <mbgl/style/style.hpp>
#include <mbgl/map/map.hpp>
#include <mbgl/style/source.hpp>

const MHExceptionName MHInvalidStyleSourceException = @"MHInvalidStyleSourceException";

@interface MHSource ()

// Even though this class is abstract, MHStyle uses it to represent some
// special internal source types like mbgl::AnnotationSource.
@property (nonatomic, readonly) mbgl::style::Source *rawSource;

@property (nonatomic, readonly, weak) id <MHStylable> stylable;

@end

@implementation MHSource {
    std::unique_ptr<mbgl::style::Source> _pendingSource;
    mapbox::base::WeakPtr<mbgl::style::Source> _weakSource;
}


- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        _identifier = [identifier copy];
    }
    return self;
}

- (instancetype)initWithRawSource:(mbgl::style::Source *)rawSource stylable:(id <MHStylable>)stylable {
    NSString *identifier = @(rawSource->getID().c_str());
    if (self = [self initWithIdentifier:identifier]) {
        _weakSource = rawSource->makeWeakPtr();
        rawSource->peer = SourceWrapper { self };
        _stylable = stylable;
    }
    return self;
}

- (mbgl::style::Source *)rawSource
{
    return _weakSource.get();
}

- (instancetype)initWithPendingSource:(std::unique_ptr<mbgl::style::Source>)pendingSource {
    if (self = [self initWithRawSource:pendingSource.get() stylable:nil]) {
        _pendingSource = std::move(pendingSource);
    }
    return self;
}

- (void)addToStylable:(id <MHStylable>)stylable {
    if (_pendingSource == nullptr) {
        [NSException raise:MHRedundantSourceException
                    format:@"This instance %@ was already added to %@. Adding the same source instance " \
         "to the style more than once is invalid.", self, stylable.style];
    }
    
    _stylable = stylable;
    _stylable.style.rawStyle->addSource(std::move(_pendingSource));
}

- (BOOL)removeFromStylable:(id <MHStylable>)mapView error:(NSError * __nullable * __nullable)outError {
    MHAssertStyleSourceIsValid();
    BOOL removed = NO;
    
    if (self.rawSource == mapView.style.rawStyle->getSource(self.identifier.UTF8String)) {
        
        auto removedSource = mapView.style.rawStyle->removeSource(self.identifier.UTF8String);
        
        if (removedSource) {
            removed = YES;
            _pendingSource = std::move(removedSource);
            _stylable = nil;
        } else if (outError) {
            NSString *localizedDescription = [NSString stringWithFormat:
                                              NSLocalizedStringWithDefaultValue(@"REMOVE_SRC_FAIL_IN_USE_FMT", @"Foundation", nil, @"The source “%@” can’t be removed while it is in use.", @"User-friendly error description; first placeholder is the source’s identifier"),
                                              self.identifier];

            *outError = [NSError errorWithDomain:MHErrorDomain
                                            code:MHErrorCodeSourceIsInUseCannotRemove
                                        userInfo:@{ NSLocalizedDescriptionKey : localizedDescription }];
        }
    } else if (outError) {
        // TODO: Consider raising an exception here
        NSString *localizedDescription = [NSString stringWithFormat:
                                          NSLocalizedStringWithDefaultValue(@"REMOVE_SRC_FAIL_MISMATCH_FMT", @"Foundation", nil, @"The source can’t be removed because its identifier, “%@”, belongs to a different source in this style.", @"User-friendly error description"),
                                          self.identifier];
        
        *outError = [NSError errorWithDomain:MHErrorDomain
                                        code:MHErrorCodeSourceIdentifierMismatch
                                    userInfo:@{ NSLocalizedDescriptionKey : localizedDescription }];
    }
    
    return removed;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@>",
            NSStringFromClass([self class]), (void *)self, self.identifier];
}

@end
