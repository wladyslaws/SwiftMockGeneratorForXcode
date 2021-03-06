import XCTest
@testable import SwiftStructureInterface

class ElementTreeUtilTests: XCTestCase {

    func test_findParentType_shouldFindImmediateParent() {
        let file = SKElementFactoryTestHelper.build(from: "class A { var a = 0 }")!
        let classType = file.children[0]
        let propertyA = classType.children[0]
        let type = ElementTreeUtil().findParentType(propertyA)
        XCTAssert(type === classType)
    }

    func test_findParentType_shouldBeNil_whenNoParents() {
        let file = SKElementFactoryTestHelper.build(from: "var a = 0")!
        let propertyA = file.children[0]
        let type = ElementTreeUtil().findParentType(propertyA)
        XCTAssertNil(type)
    }

    func test_findParentType_shouldReturnAncestorTypeElement() {
        let file = SKElementFactoryTestHelper.build(from: "class A { func a() { func b() { func c() {} } } }")!
        let classType = file.children[0]
        let innerMethod = classType.children[0].children[0].children[0]
        let type = ElementTreeUtil().findParentType(innerMethod)
        XCTAssert(type === classType)
    }

    func test_findParentType_shouldReturnNil_whenNoTypeInHierarchy() {
        let file = SKElementFactoryTestHelper.build(from: "func a() { func b() { func c() {} } }")!
        let innerMethod = file.children[0].children[0].children[0]
        let type = ElementTreeUtil().findParentType(innerMethod)
        XCTAssertNil(type)
    }

    func test_findParentType_shouldNotReturnElement_whenItIsATypeItself() {
        let file = SKElementFactoryTestHelper.build(from: "class A { func b() { class C {} } }")!
        let outerClass = file.children[0]
        let innerClass = outerClass.children[0].children[0]
        let type = ElementTreeUtil().findParentType(innerClass)
        XCTAssert(type === outerClass)
    }
}
