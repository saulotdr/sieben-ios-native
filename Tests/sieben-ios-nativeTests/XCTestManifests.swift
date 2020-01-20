import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(sieben_ios_nativeTests.allTests),
    ]
}
#endif