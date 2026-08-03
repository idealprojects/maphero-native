#import "MHStyle+MBXAdditions.h"

@implementation MHStyle (MBXAdditions)

+ (NSSet<NSString *> *)keyPathsForValuesAffectingReversedLayers {
    return [NSSet setWithObject:@"layers"];
}

- (NSArray<__kindof MHStyleLayer *> *)reversedLayers {
    return self.layers.reverseObjectEnumerator.allObjects;
}

- (void)setReversedLayers:(NSArray<__kindof MHStyleLayer *> *)reversedLayers {
    self.layers = reversedLayers.reverseObjectEnumerator.allObjects;
}

- (NSUInteger)countOfReversedLayers {
    return self.layers.count;
}

- (id)objectInReversedLayersAtIndex:(NSUInteger)index {
    NSArray *layers = self.layers;
    return layers[layers.count - 1 - index];
}

- (void)getReversedLayers:(__kindof MHStyleLayer **)buffer range:(NSRange)inRange {
    NSArray *layers = self.layers;
    for (NSUInteger i = inRange.location; i < NSMaxRange(inRange); i++) {
        MHStyleLayer *styleLayer = layers[layers.count - 1 - i];
        buffer[i] = styleLayer;
    }
}

- (void)insertObject:(__kindof MHStyleLayer *)object inReversedLayersAtIndex:(NSUInteger)index {
    [self insertLayer:object atIndex:self.layers.count - index];
}

- (void)removeObjectFromReversedLayersAtIndex:(NSUInteger)index {
    [self removeLayer:[self objectInReversedLayersAtIndex:index]];
}

@end
