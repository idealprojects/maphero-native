#import "MHMapAccessibilityElement.h"
#import "MHDistanceFormatter.h"
#import "MHCompassDirectionFormatter.h"
#import "MHFeature.h"

#import "MHGeometry_Private.h"
#import "MHVectorTileSource_Private.h"

#import "NSBundle+MHAdditions.h"
#import "NSOrthography+MHAdditions.h"
#import "NSString+MHAdditions.h"

@implementation MHMapAccessibilityElement

- (UIAccessibilityTraits)accessibilityTraits {
    return super.accessibilityTraits | UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement {
    [self.accessibilityContainer accessibilityIncrement];
}

- (void)accessibilityDecrement {
    [self.accessibilityContainer accessibilityDecrement];
}

@end

@implementation MHAnnotationAccessibilityElement

- (instancetype)initWithAccessibilityContainer:(id)container tag:(MHAnnotationTag)tag {
    if (self = [super initWithAccessibilityContainer:container]) {
        _tag = tag;
        self.accessibilityHint = NSLocalizedStringWithDefaultValue(@"ANNOTATION_A11Y_HINT", nil, nil, @"Shows more info", @"Accessibility hint");
    }
    return self;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return super.accessibilityTraits | UIAccessibilityTraitButton;
}

@end

@implementation MHFeatureAccessibilityElement

- (instancetype)initWithAccessibilityContainer:(id)container feature:(id<MHFeature>)feature {
    if (self = [super initWithAccessibilityContainer:container]) {
        _feature = feature;
        
        NSString *languageCode = [MHVectorTileSource preferredMapboxStreetsLanguage];
        NSString *nameAttribute = [NSString stringWithFormat:@"name_%@", languageCode];
        NSString *name = [feature attributeForKey:nameAttribute];

        // If a feature hasn’t been translated into the preferred language, it
        // may be in the local language, which may be written in another script.
        // Attempt to transform to the script of the preferred language, keeping
        // the original string if no transform exists or if transformation fails.
        NSString *dominantScript = [NSOrthography mgl_dominantScriptForMapboxStreetsLanguage:languageCode];
        name = [name mgl_stringByTransliteratingIntoScript:dominantScript];

        self.accessibilityLabel = name;
    }
    return self;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return super.accessibilityTraits | UIAccessibilityTraitStaticText;
}

@end

@implementation MHPlaceFeatureAccessibilityElement

- (instancetype)initWithAccessibilityContainer:(id)container feature:(id<MHFeature>)feature {
    if (self = [super initWithAccessibilityContainer:container feature:feature]) {
        NSDictionary *attributes = feature.attributes;
        NSMutableArray *facts = [NSMutableArray array];
        
        // Announce the kind of place or POI.
        NSString *languageCode = [MHVectorTileSource preferredMapboxStreetsLanguage];
        NSString *categoryAttribute = [NSString stringWithFormat:@"category_%@", languageCode];
        if (attributes[categoryAttribute]) {
            [facts addObject:attributes[categoryAttribute]];
        } else if (attributes[@"type"]) {
            // FIXME: Unfortunately, these types aren’t a closed set that can be
            // localized, since they’re based on OpenStreetMap tags.
            NSString *type = [attributes[@"type"] stringByReplacingOccurrencesOfString:@"_"
                                                                            withString:@" "];
            [facts addObject:type];
        }
        // Announce the kind of airport, rail station, or mountain based on its
        // Maki image name.
        else if (attributes[@"maki"]) {
            [facts addObject:attributes[@"maki"]];
        }
        
        // Announce the peak’s elevation in the preferred units.
        if (attributes[@"elevation_m"] ?: attributes[@"elevation_ft"]) {
            NSLengthFormatter *formatter = [[NSLengthFormatter alloc] init];
            formatter.unitStyle = NSFormattingUnitStyleLong;
            
            NSNumber *elevationValue;
            NSLengthFormatterUnit unit;
            BOOL usesMetricSystem = ![[formatter.numberFormatter.locale objectForKey:NSLocaleMeasurementSystem]
                                      isEqualToString:@"U.S."];
            if (usesMetricSystem) {
                elevationValue = attributes[@"elevation_m"];
                unit = NSLengthFormatterUnitMeter;
            } else {
                elevationValue = attributes[@"elevation_ft"];
                unit = NSLengthFormatterUnitFoot;
            }
            [facts addObject:[formatter stringFromValue:elevationValue.doubleValue unit:unit]];
        }
        
        if (facts.count) {
            NSString *separator = NSLocalizedStringWithDefaultValue(@"LIST_SEPARATOR", nil, nil, @", ", @"List separator");
            self.accessibilityValue = [facts componentsJoinedByString:separator];
        }
    }
    return self;
}

@end

@implementation MHRoadFeatureAccessibilityElement

- (instancetype)initWithAccessibilityContainer:(id)container feature:(id<MHFeature>)feature {
    if (self = [super initWithAccessibilityContainer:container feature:feature]) {
        NSDictionary *attributes = feature.attributes;
        NSMutableArray *facts = [NSMutableArray array];
        
        // Announce the route number.
        if (attributes[@"ref"]) {
            // TODO: Decorate the route number with the network name based on the shield attribute.
            NSString *ref = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"ROAD_REF_A11Y_FMT", nil, nil, @"Route %@", @"String format for accessibility value for road feature; {route number}"), attributes[@"ref"]];
            [facts addObject:ref];
        }
        
        // Announce whether the road is a one-way road.
        if ([attributes[@"oneway"] isEqualToString:@"true"]) {
            [facts addObject:NSLocalizedStringWithDefaultValue(@"ROAD_ONEWAY_A11Y_VALUE", nil, nil, @"One way", @"Accessibility value indicating that a road is a one-way road")];
        }
        
        // Announce whether the road is a divided road.
        MHPolyline *polyline;
        if ([feature isKindOfClass:[MHMultiPolylineFeature class]]) {
            [facts addObject:NSLocalizedStringWithDefaultValue(@"ROAD_DIVIDED_A11Y_VALUE", nil, nil, @"Divided road", @"Accessibility value indicating that a road is a divided road (dual carriageway)")];
            polyline = [(MHMultiPolylineFeature *)feature polylines].firstObject;
        }
        
        // Announce the road’s general direction.
        if ([feature isKindOfClass:[MHPolylineFeature class]]) {
            polyline = (MHPolylineFeature *)feature;
        }
        if (polyline) {
            NSUInteger pointCount = polyline.pointCount;
            if (pointCount) {
                CLLocationCoordinate2D *coordinates = polyline.coordinates;
                CLLocationDirection startDirection = MHDirectionBetweenCoordinates(coordinates[pointCount - 1], coordinates[0]);
                CLLocationDirection endDirection = MHDirectionBetweenCoordinates(coordinates[0], coordinates[pointCount - 1]);
                
                MHCompassDirectionFormatter *formatter = [[MHCompassDirectionFormatter alloc] init];
                formatter.unitStyle = NSFormattingUnitStyleLong;
                
                NSString *startDirectionString = [formatter stringFromDirection:startDirection];
                NSString *endDirectionString = [formatter stringFromDirection:endDirection];
                NSString *directionString = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"ROAD_DIRECTION_A11Y_FMT", nil, nil, @"%@ to %@", @"String format for accessibility value for road feature; {starting compass direction}, {ending compass direction}"), startDirectionString, endDirectionString];
                [facts addObject:directionString];
            }
        }
        
        if (facts.count) {
            NSString *separator = NSLocalizedStringWithDefaultValue(@"LIST_SEPARATOR", nil, nil, @", ", @"List separator");
            self.accessibilityValue = [facts componentsJoinedByString:separator];
        }
    }
    return self;
}

@end

@implementation MHMapViewProxyAccessibilityElement

- (instancetype)initWithAccessibilityContainer:(id)container {
    if (self = [super initWithAccessibilityContainer:container]) {
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityLabel = [self.accessibilityContainer accessibilityLabel];
        self.accessibilityHint = NSLocalizedStringWithDefaultValue(@"CLOSE_CALLOUT_A11Y_HINT", nil, nil, @"Returns to the map", @"Accessibility hint for closing the selected annotation’s callout view and returning to the map");
    }
    return self;
}

@end
