#import <XCTest/XCTest.h>

#import <Mapbox.h>

@interface MHImageSourceTests : XCTestCase

@end

@implementation MHImageSourceTests


- (void)testMHImageSourceWithImageURL {

    MHCoordinateQuad quad = { { 80, 37}, { 81, 37}, { 81, 39}, { 80, 39}};
    MHImageSource *source = [[MHImageSource alloc] initWithIdentifier:@"source-id" coordinateQuad:quad URL:[NSURL URLWithString:@"http://host/image.png"]];
    
    XCTAssertNotNil(source.URL);
    XCTAssertEqualObjects(source.URL.absoluteString, @"http://host/image.png");
    XCTAssertNil(source.image);
}

- (void)testMHImageSourceWithImage {

    NSString *imageName = @"RadarImage";
#if TARGET_OS_IPHONE
    MHImage *image = [MHImage imageNamed:imageName
                                  inBundle:[NSBundle bundleForClass:[self class]]
             compatibleWithTraitCollection:nil];
#else
    MHImage *image = [[NSBundle bundleForClass:[self class]] imageForResource:imageName];
#endif
    XCTAssertNotNil(image);

    MHCoordinateQuad quad = { { 80, 37}, { 81, 37}, { 81, 39}, { 80, 39}};
    MHImageSource *source = [[MHImageSource alloc] initWithIdentifier:@"source-id" coordinateQuad:quad image:image];
    
    XCTAssertNotNil(source.image);
    XCTAssertEqualObjects(source.image, image);
    XCTAssertNil(source.URL);
}

- (void)testMHImageSourceSetURL {
    // Create a test instance of MHImageSource
    MHCoordinateQuad quad = { { 80, 37}, { 81, 37}, { 81, 39}, { 80, 39}};
    MHImageSource *source = [[MHImageSource alloc] initWithIdentifier:@"source-id" coordinateQuad:quad URL:[NSURL URLWithString:@"http://host/image.png"]];

    // Set the URL using setURL
    NSURL *testURL = [NSURL URLWithString:@"http://host/image1.png"];
    [source setURL:testURL];

    // Assert that the URL is set correctly
    XCTAssertNotNil(source.URL);
    XCTAssertEqualObjects(source.URL.absoluteString, @"http://host/image1.png");
    XCTAssertNil(source.image);
}

- (void)testMHImageSourceSetCoordinates {
    // Create a test instance of MHImageSource
    MHCoordinateQuad quad = { { 80, 37}, { 81, 37}, { 81, 39}, { 80, 39}};
    MHImageSource *source = [[MHImageSource alloc] initWithIdentifier:@"source-id" coordinateQuad:quad URL:[NSURL URLWithString:@"http://host/image.png"]];

    // Define a new set of coordinates
    MHCoordinateQuad newQuad = { { 40, 50}, { 41, 50}, { 41, 52}, { 40, 52} };

    // Set the coordinates using the setCoordinates method
    [source setCoordinates:newQuad];

    // Get the current coordinates from the source
    MHCoordinateQuad retrievedQuad = source.coordinates;

    // Assert that the coordinates are set correctly
    XCTAssertEqual(retrievedQuad.bottomLeft.latitude, newQuad.bottomLeft.latitude);
    XCTAssertEqual(retrievedQuad.bottomLeft.longitude, newQuad.bottomLeft.longitude);
}

@end
