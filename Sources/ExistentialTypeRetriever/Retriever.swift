import SwiftSyntax
import SwiftParser

public class Retriever {
    public init() {}

    public func retrieve(source: String) -> Set<String> {
        let syntax = Parser.parse(source: source)
        let visitor = ExistentialTypeVisitor(viewMode: .all)
        visitor.walk(syntax)
        return visitor.existentialTypes
    }
}

class ExistentialTypeVisitor: SyntaxVisitor {
    var existentialTypes: Set<String> = []
    private let rawValueEnumTypes: Set<String> = [
        "Int",
        "UInt",
        "String",
        "Double",
        "Float",
        "Character",
        "Bool",
        "UInt8",
        "UInt16",
        "UInt32",
        "UInt64",
        "Int8",
        "Int16",
        "Int32",
        "Int64",
        "CGFloat"
    ]

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        existentialTypes.insert(node.name.text)
        node.inheritanceClause?.inheritedTypes.forEach { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                existentialTypes.insert(identifierType.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        existentialTypes.remove(node.name.text)

        node.inheritanceClause?.inheritedTypes.dropFirst().forEach { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                existentialTypes.insert(identifierType.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        node.inheritanceClause?.inheritedTypes.forEach { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                existentialTypes.insert(identifierType.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        node.inheritanceClause?.inheritedTypes.forEach { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self),
                !rawValueEnumTypes.contains(identifierType.name.text) {
                existentialTypes.insert(identifierType.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        node.inheritanceClause?.inheritedTypes.forEach { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                existentialTypes.insert(identifierType.name.text)
            }
        }
        return .visitChildren
    }
}
