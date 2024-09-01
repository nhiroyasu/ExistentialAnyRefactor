import XCTest
import SwiftSyntax
import SwiftParser
@testable import ExistentialAnyRefactor

final class RefactorTests: XCTestCase {
    private func assert(source: String, expected: String, file: StaticString = #file, line: UInt = #line) {
        let refactor = Refactor(existentialTypes: ["A", "B"])
        let result = refactor.exec(source)
        XCTAssertEqual(result, expected, file: file, line: line)
    }

    func testStoredProperties() {
        let source = """
        class Class {
            let a: A
            let b: B?
            let c: A & B
            let d: (A & B)?
            let e: A!
            let f: (A & B)!
        }
        """
        let expected = """
        class Class {
            let a: any A
            let b: (any B)?
            let c: any A & B
            let d: (any A & B)?
            let e: (any A)!
            let f: (any A & B)!
        }
        """

        assert(source: source, expected: expected)
    }

    func testWeekProperties() {
        let source = """
        class Class {
            weak var a: A?
            weak var b: B?
            weak var c: A & B
            weak var d: (A & B)?
        }
        """
        let expected = """
        class Class {
            weak var a: (any A)?
            weak var b: (any B)?
            weak var c: any A & B
            weak var d: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testAttributeProperties() {
        let source = """
        class Class {
            @StateObject var a: A
            @StateObject var b: B?
            @StateObject var c: A & B
            @StateObject var d: (A & B)?
        }
        """
        let expected = """
        class Class {
            @StateObject var a: any A
            @StateObject var b: (any B)?
            @StateObject var c: any A & B
            @StateObject var d: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testArrayType() {
        let source = """
        class Class {
            let a: [A]
            let b: [B?]
            let c: [A & B]
            let d: [(A & B)?]
            let e: [A!]
            let f: [(A & B)!]
            let g: [A]?
            let h: [A]!
        }
        """
        let expected = """
        class Class {
            let a: [any A]
            let b: [(any B)?]
            let c: [any A & B]
            let d: [(any A & B)?]
            let e: [(any A)!]
            let f: [(any A & B)!]
            let g: [any A]?
            let h: [any A]!
        }
        """

        assert(source: source, expected: expected)
    }

    func testDictType() {
        let source = """
        class Class {
            let a: [String: A]
            let b: [String: B?]
            let c: [String: A & B]
            let d: [String: (A & B)?]
            let e: [String: A?]
            let f: [String: (A & B)?]
            let g: [String: A]?
            let h: [String: A]!
        }
        """
        let expected = """
        class Class {
            let a: [String: any A]
            let b: [String: (any B)?]
            let c: [String: any A & B]
            let d: [String: (any A & B)?]
            let e: [String: (any A)?]
            let f: [String: (any A & B)?]
            let g: [String: any A]?
            let h: [String: any A]!
        }
        """

        assert(source: source, expected: expected)
    }

    func testInitPrams() {
        let source = """
        class Class {
            init(
                a: A,
                b: B?,
                c: A & B,
                d: (A & B)?
            ) {
            }
        }
        """
        let expected = """
        class Class {
            init(
                a: any A,
                b: (any B)?,
                c: any A & B,
                d: (any A & B)?
            ) {
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testFuncParams() {
        let source = """
        class Class {
            func f(
                a: A,
                b: B?,
                c: A & B,
                d: (A & B)?
            ) {}
        }
        """
        let expected = """
        class Class {
            func f(
                a: any A,
                b: (any B)?,
                c: any A & B,
                d: (any A & B)?
            ) {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testFuncReturn() {
        let source = """
        class Class {
            func f1() -> A
            func f2() -> B?
            func f3() -> A & B
            func f4() -> (A & B)?
        }
        """
        let expected = """
        class Class {
            func f1() -> any A
            func f2() -> (any B)?
            func f3() -> any A & B
            func f4() -> (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testClosureParams() {
        let source = """
        class Class {
            let closure: (A) -> Void
            let closure2: (A?) -> Void
            let closure3: (A & B) -> Void
            let closure4: ((A & B)?) -> Void
            let closure5: (A, B) -> Void
            let closure6: (A, C) -> Void
            let closure7: (A?, B?) -> Void

            func f(c: (A) -> Void) {}
        }
        """
        let expected = """
        class Class {
            let closure: (any A) -> Void
            let closure2: ((any A)?) -> Void
            let closure3: (any A & B) -> Void
            let closure4: ((any A & B)?) -> Void
            let closure5: (any A, any B) -> Void
            let closure6: (any A, C) -> Void
            let closure7: ((any A)?, (any B)?) -> Void

            func f(c: (any A) -> Void) {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testClosureReturn() {
        let source = """
        class Class {
            let closure: () -> A
            let closure4: () -> B?
            let closure3: () -> A & B
            let closure3: () -> (A & B)?

            func f(() -> A) {}
            func f(() -> A?) {}
        }
        """
        let expected = """
        class Class {
            let closure: () -> any A
            let closure4: () -> (any B)?
            let closure3: () -> any A & B
            let closure3: () -> (any A & B)?

            func f(() -> any A) {}
            func f(() -> (any A)?) {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testCodeBlocks() {
        let source = """
        class Class {
            var a: A {
                let _a: A = ClassA()
                return _a
            }

            init() {
                let a: A = ClassA()
                let a: A & B = ClassAB()
            }

            func f() {
                let a: A = ClassA()
                let a: A & B = ClassAB()
            }
        }
        """
        let expected = """
        class Class {
            var a: any A {
                let _a: any A = ClassA()
                return _a
            }

            init() {
                let a: any A = ClassA()
                let a: any A & B = ClassAB()
            }

            func f() {
                let a: any A = ClassA()
                let a: any A & B = ClassAB()
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testInlineBlock() {
        let source = """
        var a: A = ClassA()
        var b: A & B = ClassAB()
        func f(b: B) -> A { return ClassA() }
        typealias H = (Result<B, A>) -> Void
        """

        let expected = """
        var a: any A = ClassA()
        var b: any A & B = ClassAB()
        func f(b: any B) -> any A { return ClassA() }
        typealias H = (Result<any B, any A>) -> Void
        """

        assert(source: source, expected: expected)
    }

    func testResultType() {
        let source = """
        class Class {
            func f(completion: @escaping (Result<A, B>) -> Void) {}
            func f(c: @escaping ((Result<Void, A>) -> Void)) {}
            func f() -> Result<A, B> {}
            var r: Result<A, B>
        }
        """
        let expected = """
        class Class {
            func f(completion: @escaping (Result<any A, any B>) -> Void) {}
            func f(c: @escaping ((Result<Void, any A>) -> Void)) {}
            func f() -> Result<any A, any B> {}
            var r: Result<any A, any B>
        }
        """

        assert(source: source, expected: expected)
    }

    func testResultType2() {
        let source = """
        class Class {
            func f(c: @escaping ((Result<Void, A>) -> Void)) {}
        }
        """
        let expected = """
        class Class {
            func f(c: @escaping ((Result<Void, any A>) -> Void)) {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testResultType3() {
        let source = """
        class Class {
            func f(completion: @escaping ((Swift.Result<Void, A>) -> Void))
        }
        """
        let expected = """
        class Class {
            func f(completion: @escaping ((Swift.Result<Void, any A>) -> Void))
        }
        """

        assert(source: source, expected: expected)
    }

    func testTypeAliasAtRoot() {
        let source = """
        public typealias H = (Swift.Result<B, A>) -> Void
        """
        let expected = """
        public typealias H = (Swift.Result<any B, any A>) -> Void
        """

        assert(source: source, expected: expected)
    }

    func testTypeAliasAtClass() {
        let source = """
        class Class {
            typealias H = (Swift.Result<B, A>) -> Void
        }
        """
        let expected = """
        class Class {
            typealias H = (Swift.Result<any B, any A>) -> Void
        }
        """

        assert(source: source, expected: expected)
    }

    func testResultTypeWithOptional() {
        let source = """
        class Class {
            func f(completion: @escaping (Result<A?, B?>) -> Void) {}
            func f() -> Result<A?, B?> {}
            func f(c: @escaping ((Result<Void, A?>) -> Void)) {}
        }
        """
        let expected = """
        class Class {
            func f(completion: @escaping (Result<(any A)?, (any B)?>) -> Void) {}
            func f() -> Result<(any A)?, (any B)?> {}
            func f(c: @escaping ((Result<Void, (any A)?>) -> Void)) {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInFunc() {
        let source = """
        class Class {
            func f() -> A {
                var b: B = ClassB as? B
                D.shared.f { b as? B }
                return ClassA() as! A
            }
        }
        """
        let expected = """
        class Class {
            func f() -> any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInGetter() {
        let source = """
        class Class {
            var a: A {
                var b: B = ClassB as? B
                D.shared.f { b as? B }
                return ClassA() as! A
            }
        }
        """
        let expected = """
        class Class {
            var a: any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInClosure() {
        let source = """
        func f() {
            f2(c: {
                var b: B = ClassB as? B
                D.shared.f { b as? B }
                return ClassA() as! A
            })
        }
        """
        let expected = """
        func f() {
            f2(c: {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            })
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInInit() {
        let source = """
        class Class {
            init {
                var b: B = ClassB as? B
                D.shared.f { b as? B }
            }
        }
        """
        let expected = """
        class Class {
            init {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testExistentialTypeSelf() {
        let source = """
        func f() {
            register(A.self) { _ in AClass() as A }
            S.shared.f(A.self)?.f2()
            S.shared.f(A.self)!.f2()
        }
        """
        let expected = """
        func f() {
            register((any A).self) { _ in AClass() as (any A) }
            S.shared.f((any A).self)?.f2()
            S.shared.f((any A).self)!.f2()
        }
        """

        assert(source: source, expected: expected)
    }

    func testExistentialTypeSelfInGetter() {
        let source = """
        var a: any A {
            register(A.self) { _ in AClass() as A }
            register(B.self) { _ in BClass() as B }.share()
        }
        """
        let expected = """
        var a: any A {
            register((any A).self) { _ in AClass() as (any A) }
            register((any B).self) { _ in BClass() as (any B) }.share()
        }
        """

        assert(source: source, expected: expected)
    }

    func testExistentialTypeSelfInInit() {
        let source = """
        class C {
            init {
                register(A.self) { _ in AClass() as A }
            }
        }
        """
        let expected = """
        class C {
            init {
                register((any A).self) { _ in AClass() as (any A) }
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testExistentialTypeSelfInArgs() {
        let source = """
        func f(a: A = A.self) {}
        """
        let expected = """
        func f(a: any A = (any A).self) {}
        """

        assert(source: source, expected: expected)
    }


    func testExistentialTypeSelfInInitArgs() {
        let source = """
        class C {
            init(a: A = A.self) {}
        }
        """
        let expected = """
        class C {
            init(a: any A = (any A).self) {}
        }
        """

        assert(source: source, expected: expected)
    }

    // MARK: - not applied cases

    func testNotExistentialType() {
        let source = """
        class Class {
            let a: C
            let b: C?
            let c: C & D
            let d: (C & D)?
        }
        """
        let expected = """
        class Class {
            let a: C
            let b: C?
            let c: C & D
            let d: (C & D)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithGenericsAtFunc() {
        let source = """
        class Class {
            func f<A: C>(a: A) -> A {
                return ClassA()
            }
        }
        """
        let expected = """
        class Class {
            func f<A: C>(a: A) -> A {
                return ClassA()
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithGenericsAtClass() {
        let source = """
        class Class<A: C> {
            let a: A
            let b: A?
            let c: A & D
            let d: (A & D)?
        }
        """
        let expected = """
        class Class<A: C> {
            let a: A
            let b: A?
            let c: A & D
            let d: (A & D)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithTypealias() {
        let source = """
        class Class {
            typealias B = O
            let a: B
            let b: B?
            let c: B & D
            let d: (B & D)?
        }
        """
        let expected = """
        class Class {
            typealias B = O
            let a: B
            let b: B?
            let c: B & D
            let d: (B & D)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithNestedType() {
        let source = """
        class Class {
            struct B {}

            let b: B
        }
        """
        let expected = """
        class Class {
            struct B {}

            let b: B
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithNestedType2() {
        let source = """
        extension E {
            struct B {
                typealias A = O
                let a: A
            }
        }
        """
        let expected = """
        extension E {
            struct B {
                typealias A = O
                let a: A
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWithAssosiateType() {
        let source = """
        protocol P {
            associatedtype A
            var a: A { get }
        }
        """
        let expected = """
        protocol P {
            associatedtype A
            var a: A { get }
        }
        """

        assert(source: source, expected: expected)
    }

    func testResultTypeWithAny() {
        let source = """
        class Class {
            func f(completion: @escaping (Result<any A, any B>) -> Void) {}
            func f() -> Result<any A, any B> {}
        }
        """
        let expected = """
        class Class {
            func f(completion: @escaping (Result<any A, any B>) -> Void) {}
            func f() -> Result<any A, any B> {}
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInFuncWithAny() {
        let source = """
        class Class {
            func f() -> any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """
        let expected = """
        class Class {
            func f() -> any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInGetterWithAny() {
        let source = """
        class Class {
            var a: any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """
        let expected = """
        class Class {
            var a: any A {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testAsInClosureWitAny() {
        let source = """
        func f() {
            f2(c: {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            })
        }
        """
        let expected = """
        func f() {
            f2(c: {
                var b: any B = ClassB as? (any B)
                D.shared.f { b as? (any B) }
                return ClassA() as! (any A)
            })
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeWeakVar() {
        let source = """
        class Class {
            weak var a: C?
            weak var b: C & D
            weak var c: (C & D)?
        }
        """
        let expected = """
        class Class {
            weak var a: C?
            weak var b: C & D
            weak var c: (C & D)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeSelf() {
        let source = """
        func f() {
            register(C.self) { _ in CClass() as C }
            S.shared.f(C.self)?.f2()
            S.shared.f(C.self)!.f2()
        }
        """
        let expected = """
        func f() {
            register(C.self) { _ in CClass() as C }
            S.shared.f(C.self)?.f2()
            S.shared.f(C.self)!.f2()
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotExistentialTypeSelfInArgs() {
        let source = """
        func f(a: C = C.self) {}
        """
        let expected = """
        func f(a: C = C.self) {}
        """

        assert(source: source, expected: expected)
    }


    func testNotExistentialTypeSelfInInitArgs() {
        let source = """
        class C {
            init(a: C = C.self) {}
        }
        """
        let expected = """
        class C {
            init(a: C = C.self) {}
        }
        """

        assert(source: source, expected: expected)
    }


     // MARK: - Regular cases

    func testRefactorNotAnySyntaxForStoredProperties() {
        let source = """
        class Class {
            let anyProtocol: A
            let optionalAnyProtocol: A?
            let anyAndOtherProtocol: A & B
            let optionalAnyAndOtherProtocol: (A & B)?
        }
        """
        let expected = """
        class Class {
            let anyProtocol: any A
            let optionalAnyProtocol: (any A)?
            let anyAndOtherProtocol: any A & B
            let optionalAnyAndOtherProtocol: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxForTemporaryProperties() {
        let source = """
        func f() {
            let anyProtocol: A = ProtocolImpl()
            let optionalAnyProtocol: A? = nil
            let anyAndOtherProtocol: A & B = ProtocolImpl()
            let optionalAnyAndOtherProtocol: (A & B)? = nil
        }
        """
        let expected = """
        func f() {
            let anyProtocol: any A = ProtocolImpl()
            let optionalAnyProtocol: (any A)? = nil
            let anyAndOtherProtocol: any A & B = ProtocolImpl()
            let optionalAnyAndOtherProtocol: (any A & B)? = nil
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxForFunctionParameters() {
        let source = """
        class Class {
            func f(
                a: A,
                b: A?,
                c: A & B,
                d: (A & B)?
            ) -> Data {
                return Data()
            }
        }
        """
        let expected = """
        class Class {
            func f(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) -> Data {
                return Data()
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxForReturnType() {
        let source = """
        class Class {
            func f1() -> A
            func f2() -> A?
            func f3() -> A & B
            func f4() -> (A & B)?
        }
        """
        let expected = """
        class Class {
            func f1() -> any A
            func f2() -> (any A)?
            func f3() -> any A & B
            func f4() -> (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxForComputedProperties() {
        let source = """
        class Class {
            var anyProtocol: A { get }
            var optionalAnyProtocol: A? { get }
            var anyAndOtherProtocol: A & B { get }
            var optionalAnyAndOtherProtocol: (A & B)? { get }
        }
        """
        let expected = """
        class Class {
            var anyProtocol: any A { get }
            var optionalAnyProtocol: (any A)? { get }
            var anyAndOtherProtocol: any A & B { get }
            var optionalAnyAndOtherProtocol: (any A & B)? { get }
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxForInitType() {
        let source = """
        class Class {
            init(
                a: A,
                b: A?,
                c: A & B,
                d: (A & B)?
            ) {
            }
        }
        """
        let expected = """
        class Class {
            init(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) {
            }
        }
        """

        assert(source: source, expected: expected)
    }

    // MARK: - Stored Properties with any attribute cases

    func testRefactorNotAnySyntaxWithOtherClassForStoredProperties() {
        let source = """
        class Class {
            let anyAndOtherProtocol: A & ClassA
            let optionalAnyAndOtherProtocol: (A & ClassA)?
        }
        """
        let expected = """
        class Class {
            let anyAndOtherProtocol: any A & ClassA
            let optionalAnyAndOtherProtocol: (any A & ClassA)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxWithAttributedSyntaxForStoredProperties() {
        let source = """
        class Class {
            @StateObject var anyProtocol: A
            @StateObject var optionalAnyProtocol: A?
            @StateObject var anyAndOtherProtocol: A & B
            @StateObject var optionalAnyAndOtherProtocol: (A & B)?
        }
        """
        let expected = """
        class Class {
            @StateObject var anyProtocol: any A
            @StateObject var optionalAnyProtocol: (any A)?
            @StateObject var anyAndOtherProtocol: any A & B
            @StateObject var optionalAnyAndOtherProtocol: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testRefactorNotAnySyntaxWithWeakSyntaxForStoredProperties() {
        let source = """
        class Class {
            weak var optionalAnyProtocol: A?
            weak var optionalAnyAndOtherProtocol: (A & B)?
            weak var anyProtocol: A!
            weak var anyAndOtherProtocol: (A & B)!
            weak var handler: ((Result<A!, B?>) -> Void)
        }
        """
        let expected = """
        class Class {
            weak var optionalAnyProtocol: (any A)?
            weak var optionalAnyAndOtherProtocol: (any A & B)?
            weak var anyProtocol: (any A)!
            weak var anyAndOtherProtocol: (any A & B)!
            weak var handler: ((Result<(any A)!, (any B)?>) -> Void)
        }
        """

        assert(source: source, expected: expected)
    }

    // MARK: - Already marked any syntax

    func testNotRefactorAlreadyAnySyntaxForStoredProperty() {
        let source = """
        class Class {
            let anyProtocol: any A
            let optionalAnyProtocol: (any A)?
            let anyAndOtherProtocol: any A & B
            let optionalAnyAndOtherProtocol: (any A & B)?
        }
        """
        let expected = """
        class Class {
            let anyProtocol: any A
            let optionalAnyProtocol: (any A)?
            let anyAndOtherProtocol: any A & B
            let optionalAnyAndOtherProtocol: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxForTemporaryProperty() {
        let source = """
        func f() {
            let anyProtocol: any A = ProtocolImpl()
            let optionalAnyProtocol: (any A)? = nil
            let anyAndOtherProtocol: any A & B = ProtocolImpl()
            let optionalAnyAndOtherProtocol: (any A & B)? = nil
        }
        """
        let expected = """
        func f() {
            let anyProtocol: any A = ProtocolImpl()
            let optionalAnyProtocol: (any A)? = nil
            let anyAndOtherProtocol: any A & B = ProtocolImpl()
            let optionalAnyAndOtherProtocol: (any A & B)? = nil
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxForFunctionParameter() {
        let source = """
        class Class {
            func f(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) -> Data {
                return Data()
            }
        }
        """
        let expected = """
        class Class {
            func f(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) -> Data {
                return Data()
            }
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxForReturnType() {
        let source = """
        class Class {
            func f1() -> any A
            func f2() -> (any A)?
            func f3() -> any A & B
            func f4() -> (any A & B)?
        }
        """
        let expected = """
        class Class {
            func f1() -> any A
            func f2() -> (any A)?
            func f3() -> any A & B
            func f4() -> (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxForComputedProperty() {
        let source = """
        class Class {
            var anyProtocol: any A { get }
            var optionalAnyProtocol: (any A)? { get }
            var anyAndOtherProtocol: any A & B { get }
            var optionalAnyAndOtherProtocol: (any A & B)? { get }
        }
        """
        let expected = """
        class Class {
            var anyProtocol: any A { get }
            var optionalAnyProtocol: (any A)? { get }
            var anyAndOtherProtocol: any A & B { get }
            var optionalAnyAndOtherProtocol: (any A & B)? { get }
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxForInitType() {
        let source = """
        class Class {
            init(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) {
            }
        }
        """
        let expected = """
        class Class {
            init(
                a: any A,
                b: (any A)?,
                c: any A & B,
                d: (any A & B)?
            ) {
            }
        }
        """

        assert(source: source, expected: expected)
    }

    // MARK: - Already marked any syntax with other class

    func testNotRefactorAlreadyAnySyntaxWithOtherClassForStoredProperty() {
        let source = """
        class Class {
            let anyAndOtherProtocol: any A & ClassA
            let optionalAnyAndOtherProtocol: (any A & ClassA)?
        }
        """
        let expected = """
        class Class {
            let anyAndOtherProtocol: any A & ClassA
            let optionalAnyAndOtherProtocol: (any A & ClassA)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxWithAttributedSyntaxForStoredProperty() {
        let source = """
        class Class {
            @StateObject var anyProtocol: any A
            @StateObject var optionalAnyProtocol: (any A)?
            @StateObject var anyAndOtherProtocol: any A & B
            @StateObject var optionalAnyAndOtherProtocol: (any A & B)?
        }
        """
        let expected = """
        class Class {
            @StateObject var anyProtocol: any A
            @StateObject var optionalAnyProtocol: (any A)?
            @StateObject var anyAndOtherProtocol: any A & B
            @StateObject var optionalAnyAndOtherProtocol: (any A & B)?
        }
        """

        assert(source: source, expected: expected)
    }

    func testNotRefactorAlreadyAnySyntaxWithWeakSyntaxForStoredProperty() {
        let source = """
        class Class {
            weak var optionalAnyProtocol: (any A)?
            weak var optionalAnyAndOtherProtocol: (any A & B)?
            weak var anyProtocol: (any A)!
            weak var anyAndOtherProtocol: (any A & B)!
        }
        """
        let expected = """
        class Class {
            weak var optionalAnyProtocol: (any A)?
            weak var optionalAnyAndOtherProtocol: (any A & B)?
            weak var anyProtocol: (any A)!
            weak var anyAndOtherProtocol: (any A & B)!
        }
        """

        assert(source: source, expected: expected)
    }
}
