import XCTest

import MockingBird

class StubbingTests: XCTestCase {

    let mock = MockHub()

    func testCanStubAFunction() {
        mock.mb.stub(function: "greet", return: "What's up")

        XCTAssertEqual("What's up", mock.greet())
    }

    func testCanStubConditionally() {
        mock.mb.stub(function: "say", whenCalledWith: [1], return: "One")
        mock.mb.stub(function: "say", whenCalledWith: [2], return: "Two")

        XCTAssertEqual("One", mock.say(number: 1))
        XCTAssertEqual("Two", mock.say(number: 2))
    }

    func testConditionalStubbingWithStructParams() {
        mock.mb.stub(function: "getNumber", whenCalledWith: [TestStruct(num: 1, name: "Hi")], return: 5)
        mock.mb.stub(function: "getNumber", whenCalledWith: [TestStruct(num: 3, name: "Yo")], return: 2)
        let thirdStruct = TestStruct(num: 7, name: "Third")
        mock.mb.stub(function: "getNumber", whenCalledWith: [thirdStruct], return: 9)

        XCTAssertEqual(5, mock.getNumber(fromStruct: TestStruct(num: 1, name: "Hi")))
        XCTAssertEqual(2, mock.getNumber(fromStruct: TestStruct(num: 3, name: "Yo")))
        XCTAssertEqual(9, mock.getNumber(fromStruct: thirdStruct))
    }

    func testLastInWins() {
        mock.mb.stub(function: "say", whenCalledWith: [2], return: "One")
        mock.mb.stub(function: "say", whenCalledWith: [2], return: "Two")

        XCTAssertEqual("Two", mock.say(number: 2))
    }
}

struct TestStruct {
    let num: Int
    let name: String
}

protocol InfoHub {
    func greet() -> String
    func say(number: Int) -> String
    func getNumber(fromStruct: TestStruct) -> Int
}

struct MockHub: InfoHub {
    var mb = MockingBird()

    func greet() -> String {
        return mb.returnValue(for: "greet") ?? ""
    }

    func say(number: Int) -> String {
        return mb.returnValue(for: "say", whenCalledWith: [number]) ?? ""
    }

    func getNumber(fromStruct s: TestStruct) -> Int {
        return mb.returnValue(for: "getNumber", whenCalledWith: [s]) ?? 0
    }
}
