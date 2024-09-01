import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class RootRewriter: SyntaxRewriter {
    let existentialTypes: Set<String>

    init(existentialTypes: Set<String>) {
        self.existentialTypes = existentialTypes
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)
        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        var mutableExistentialTypes = existentialTypes

        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                mutableExistentialTypes.remove(genericSyntax.name.text)
            }
        }
        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: mutableExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        let adjustedExistentialTypes = existentialTypes.subtracting(ExcludeExistentialTypeDetector().exec(node, existentialTypes: existentialTypes))

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: adjustedExistentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var mutableNode = node

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: existentialTypes)

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        var mutableNode = node

        mutableNode = rewriteExistentialType(mutableNode, existentialTypes: existentialTypes)

        return DeclSyntax(mutableNode)
    }
}

func rootRewriter<S: SyntaxProtocol>(_ syntax: S, existentialTypes: Set<String>) -> S {
    RootRewriter(existentialTypes: existentialTypes).rewrite(syntax).as(S.self)!
}
