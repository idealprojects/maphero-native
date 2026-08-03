#import "MHFoundation.h"

@protocol MHFeature;

NS_ASSUME_NONNULL_BEGIN

/**
 An `NSUInteger` constant used to indicate an invalid cluster identifier.
 This indicates a missing cluster feature.
 */
FOUNDATION_EXTERN MH_EXPORT const NSUInteger MHClusterIdentifierInvalid;

/**
 A protocol that feature subclasses (i.e. those already conforming to
 the ``MHFeature`` protocol) conform to if they represent clusters.

 Currently the only class that conforms to ``MHCluster`` is
 ``MHPointFeatureCluster`` (a subclass of ``MHPointFeatureCluster``).

 To check if a feature is a cluster, check conformity to ``MHCluster``, for
 example:

 ```swift
 let shape = try! MHShape(data: clusterShapeData, encoding: String.Encoding.utf8.rawValue)

 guard let pointFeature = shape as? MHPointFeature else {
     throw ExampleError.unexpectedFeatureType
 }

 // Check for cluster conformance
 guard let cluster = pointFeature as? MHCluster else {
     throw ExampleError.featureIsNotACluster
 }

 // Currently the only supported class that conforms to ``MHCluster`` is
 // ``MHPointFeatureCluster``
 guard cluster is MHPointFeatureCluster else {
     throw ExampleError.unexpectedFeatureType
 }
 ```
 */
MH_EXPORT
@protocol MHCluster <MHFeature>

/** The identifier for the cluster. */
@property (nonatomic, readonly) NSUInteger clusterIdentifier;

/** The number of points within this cluster */
@property (nonatomic, readonly) NSUInteger clusterPointCount;

@end

NS_ASSUME_NONNULL_END
