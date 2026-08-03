import MapHero
import XCTest

class CustomAnnotationView: MHAnnotationView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class MHAnnotationViewIntegrationTests: XCTestCase {
    func testCreatingCustomAnnotationView() {
        let customAnnotationView = CustomAnnotationView(reuseIdentifier: "resuse-id")
        XCTAssertNotNil(customAnnotationView)
    }
}
