import XCTest
@testable import PostureCore

final class PostureCoreTests: XCTestCase {
    func testDegreesConversion() {
        XCTAssertEqual(PostureCore.degrees(fromRadians: .pi / 2), 90, accuracy: 1e-9)
    }
}
