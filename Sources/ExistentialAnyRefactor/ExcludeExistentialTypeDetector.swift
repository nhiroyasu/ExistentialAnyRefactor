import SwiftSyntax

class ExcludeExistentialTypeDetector {
    func exec(_ syntax: SyntaxProtocol, existentialTypes: Set<String>) -> Set<String> {
        let visitor = ExcludeExistentialTypeVisitor(viewMode: .all, existentialTypes: existentialTypes)
        visitor.walk(syntax)
        return visitor.excludeExistentialTypes
    }
}

class ExcludeExistentialTypeVisitor: SyntaxVisitor {
    var excludeExistentialTypes: Set<String> = []
    let existentialTypes: Set<String>

    init(viewMode: SyntaxTreeViewMode, existentialTypes: Set<String>) {
        self.existentialTypes = existentialTypes
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                excludeExistentialTypes.insert(genericSyntax.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                excludeExistentialTypes.insert(genericSyntax.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                excludeExistentialTypes.insert(genericSyntax.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                excludeExistentialTypes.insert(genericSyntax.name.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        excludeExistentialTypes.insert(node.name.text)
        return .visitChildren
    }
}
