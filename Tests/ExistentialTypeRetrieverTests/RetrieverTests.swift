import XCTest
import SwiftSyntax
import SwiftParser
@testable import ExistentialTypeRetriever

class RetrieverTests: XCTestCase {

    private func assert(source: String, expected: Set<String>) {
        let retriever = Retriever()
        let result = retriever.retrieve(source: source)
        XCTAssertEqual(result, expected)
    }

    func testProtocol() {
        let source = """
        protocol P: A, B {
        }
        """

        assert(source: source, expected: ["P", "A", "B"])
    }

    func testClass() {
        let source = """
        class C: A, B {
        }
        """

        assert(source: source, expected: ["B"])
    }

    func testStruct() {
        let source = """
        struct S: A, B {
        }
        """

        assert(source: source, expected: ["A", "B"])
    }

    func testEnum() {
        let source = """
        enum E: String, A, B {
        }
        """

        assert(source: source, expected: ["A", "B"])
    }

    func testExtension() {
        let source = """
        extension E: A, B {
        }
        """

        assert(source: source, expected: ["A", "B"])
    }

    func testMixed() {
        let source = """
        protocol P: A, B {
        }

        class C: A, B {
        }

        struct S: A, B {
        }

        enum E: A, B {
        }

        extension E: A, B {
        }
        """

        assert(source: source, expected: ["P", "A", "B"])
    }

    func testGenerics() {
        let source = """
        class C<T: P>: A, B {
        }

        class D<T: P>: C<T>, E {
        }
        """

        assert(source: source, expected: ["B", "E"])
    }

    func testNest() {
        let source = """
        struct C: A, P {
            struct D: B, P {
                struct E: C, P {
                }
            }
        }
        """

        assert(source: source, expected: ["A", "B", "C", "P"])
    }
}
