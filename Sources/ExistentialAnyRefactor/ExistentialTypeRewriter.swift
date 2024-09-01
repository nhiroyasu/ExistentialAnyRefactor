import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

/// Rewrite the syntax tree to replace all the existential types with `any`.
///
/// # Example
/// ```swift
/// var x: A -> var x: any A
/// func f(a: A) -> A -> func f(a: any A) -> any A
/// ```
class ExistentialTypeRewriter: SyntaxRewriter {
    let existentialTypes: Set<String>

    init(existentialTypes: Set<String>) {
        self.existentialTypes = existentialTypes
    }

    // MARK: - Declare Syntax

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var mutableNode = node

        var newBindings: [PatternBindingSyntax] = []
        for i in 0 ..< node.bindings.count {
            let binding = node.bindings[node.bindings.index(at: i)]
            var mutableBinding = binding
            /// var a: **A**
            if let typeAnnotation = binding.typeAnnotation {
                let anyType = refactor(typeAnnotation.type, existentialTypes: existentialTypes)
                let newTypeAnnotation = typeAnnotation.with(\.type, anyType)
                mutableBinding = mutableBinding.with(\.typeAnnotation, newTypeAnnotation)
            }
            /// var a: A **{ ... }**
            if let accessorBlock = binding.accessorBlock {
                let newAccessorBlock = rewriteExistentialType(accessorBlock, existentialTypes: existentialTypes)
                mutableBinding = mutableBinding.with(\.accessorBlock, newAccessorBlock)
            }
            /// var a: A = **ClassA() as A**
            if let initializer = binding.initializer,
               let sequenceExpr = initializer.value.as(SequenceExprSyntax.self) {
                let newSequenceExpr = rewriteExistentialType(sequenceExpr, existentialTypes: existentialTypes)
                let newInitializer = initializer.with(\.value, ExprSyntax(newSequenceExpr))
                mutableBinding = mutableBinding.with(\.initializer, newInitializer)
            }
            newBindings.append(mutableBinding)
        }

        mutableNode = mutableNode.with(\.bindings, PatternBindingListBuilder.buildFinalResult(
            PatternBindingListBuilder.buildBlock(newBindings)
        ))
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

        /// func f(**a: A, b: B**) -> A
        let parameters = node.signature.parameterClause.parameters
        var newParameters: [FunctionParameterSyntax] = []
        for i in 0 ..< parameters.count {
            let parameter = parameters[parameters.index(at: i)]
            let anyType = refactor(parameter.type, existentialTypes: mutableExistentialTypes)
            var mutableParameter = parameter.with(\.type, anyType)
            if let defaultValue = mutableParameter.defaultValue {
                let defaultValueExprAnyType = rewriteExistentialType(defaultValue.value, existentialTypes: mutableExistentialTypes)
                let newDefaultValue = defaultValue.with(\.value, defaultValueExprAnyType)
                mutableParameter = mutableParameter.with(\.defaultValue, newDefaultValue)
            }
            newParameters.append(mutableParameter)
        }
        let newParameterListSyntax = FunctionParameterListBuilder.buildFinalResult(
            FunctionParameterListBuilder.buildBlock(newParameters)
        )
        mutableNode = node.with(\.signature.parameterClause.parameters, newParameterListSyntax)

        /// func f(a: A) -> **A**
        if let returnClause = node.signature.returnClause {
            let newReturnType = refactor(returnClause.type, existentialTypes: mutableExistentialTypes)
            let newReturnClause = returnClause.with(\.type, newReturnType)
            mutableNode = mutableNode.with(\.signature.returnClause, newReturnClause)
        }

        /// func f() **{ ... }**
        if let bodySyntax = node.body {
            let newBody = rewriteExistentialType(bodySyntax, existentialTypes: mutableExistentialTypes)
            mutableNode = mutableNode.with(\.body, newBody)
        }

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        var mutableExistentialTypes = existentialTypes

        if let genericParameterClause = node.genericParameterClause {
            genericParameterClause.parameters.forEach { genericSyntax in
                mutableExistentialTypes.remove(genericSyntax.name.text)
            }
        }

        /// init(**a: A, b: B**)
        let parameters = node.signature.parameterClause.parameters
        var newParameters: [FunctionParameterSyntax] = []
        for i in 0 ..< parameters.count {
            let parameter = parameters[parameters.index(at: i)]
            let anyType = refactor(parameter.type, existentialTypes: mutableExistentialTypes)
            var mutableParameter = parameter.with(\.type, anyType)
            if let defaultValue = mutableParameter.defaultValue {
                let defaultValueExprAnyType = rewriteExistentialType(defaultValue.value, existentialTypes: mutableExistentialTypes)
                let newDefaultValue = defaultValue.with(\.value, defaultValueExprAnyType)
                mutableParameter = mutableParameter.with(\.defaultValue, newDefaultValue)
            }
            newParameters.append(mutableParameter)
        }
        let newParameterListSyntax = FunctionParameterListBuilder.buildFinalResult(
            FunctionParameterListBuilder.buildBlock(newParameters)
        )
        mutableNode = mutableNode.with(\.signature.parameterClause.parameters, newParameterListSyntax)

        /// init() **{ ... }**
        if let bodySyntax = node.body {
            let newBody = rewriteExistentialType(bodySyntax, existentialTypes: mutableExistentialTypes)
            mutableNode = mutableNode.with(\.body, newBody)
        }

        return DeclSyntax(mutableNode)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        /// typealias A = **B**
        let newInitializerValue = refactor(node.initializer.value, existentialTypes: existentialTypes)
        let newTypeAliasDecl = node.with(\.initializer.value, newInitializerValue)
        return DeclSyntax(newTypeAliasDecl)
    }

    // MARK: - Expression Syntax

    /// Rewrite the sequence expression syntax to replace all the existential types with `any`.
    ///
    /// # Example
    /// Before
    /// ```swift
    /// let tmp = a as A
    /// ```
    /// After
    /// ```swift
    /// let tmp = a as (any A)
    /// ```
    override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
        guard let asIndex = node.elements.firstIndex(where: { $0.as(UnresolvedAsExprSyntax.self) != nil }) else {
            return ExprSyntax(node)
        }

        guard let typeExprSyntax = node.elements[node.elements.index(after: asIndex)].as(TypeExprSyntax.self) else {
            return ExprSyntax(node)
        }

        let newType = refactor(typeExprSyntax.type.trimmed, existentialTypes: existentialTypes)
        guard newType.description != typeExprSyntax.type.trimmed.description else {
            return ExprSyntax(node)
        }

        let tupleSyntax = TupleTypeSyntax(
            leadingTrivia: typeExprSyntax.type.leadingTrivia,
            elements: TupleTypeElementListBuilder.buildFinalResult(
                TupleTypeElementListBuilder.buildBlock(
                    [TupleTypeElementSyntax(type: newType)]
                )
            ),
            trailingTrivia: typeExprSyntax.type.trailingTrivia
        )
        let newExprSyntax = typeExprSyntax.with(\.type, TypeSyntax(tupleSyntax))

        var mutableExprList: [ExprSyntax] = []
        node.elements.forEach { expr in
            if node.elements[node.elements.index(after: asIndex)] == expr {
                mutableExprList.append(ExprSyntax(newExprSyntax))
            } else {
                mutableExprList.append(expr)
            }
        }
        let newExprList = ExprListBuilder.buildFinalResult(ExprListBuilder.buildBlock(mutableExprList))
        let newSequenceExpr = SequenceExprSyntax(elements: newExprList)
        return ExprSyntax(newSequenceExpr)
    }

    /// Rewrite the member access expression syntax to replace all the existential types with `any`.
    /// 
    /// # Example
    /// Before
    /// ```swift
    /// let tmp = fetch(A.self)
    /// ```
    /// After
    /// ```swift
    /// let tmp = fetch((any A).self)
    /// ```
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        var mutableNode = node
        if let base = mutableNode.base {
            let newBase = rewriteExistentialType(base, existentialTypes: existentialTypes)
            mutableNode = mutableNode.with(\.base, newBase)
        }

        guard let referenceType = mutableNode.base?.as(DeclReferenceExprSyntax.self)?.baseName,
              existentialTypes.contains(referenceType.text),
              mutableNode.declName.baseName.text == "self" else {
            return ExprSyntax(mutableNode)
        }

        let anyType = SomeOrAnyTypeSyntax(
            leadingTrivia: referenceType.leadingTrivia,
            someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
            constraint: IdentifierTypeSyntax(name: referenceType),
            trailingTrivia: referenceType.trailingTrivia
        )
        let anyTypeExpr = TypeExprSyntax(type: anyType)
        let tupleExprSyntax = TupleExprSyntax(
            elements: LabeledExprListBuilder.buildFinalResult(
                LabeledExprListBuilder.buildBlock([LabeledExprSyntax(expression: anyTypeExpr)])
            )
        )
        let newMemberAccessExpr = mutableNode.with(\.base, ExprSyntax(tupleExprSyntax))
        return ExprSyntax(newMemberAccessExpr)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let newArguments = rewriteExistentialType(node.arguments, existentialTypes: existentialTypes)
        var newNode = node.with(\.arguments, newArguments)
        let newCalledExpression = rewriteExistentialType(node.calledExpression, existentialTypes: existentialTypes)
        newNode = newNode.with(\.calledExpression, newCalledExpression)
        if let trailingClosure = newNode.trailingClosure {
            let newTrailingClosure = rewriteExistentialType(trailingClosure, existentialTypes: existentialTypes)
            newNode = newNode.with(\.trailingClosure, newTrailingClosure)
        }
        return ExprSyntax(newNode)
    }

    override func visit(_ node: OptionalChainingExprSyntax) -> ExprSyntax {
        let newExpression = rewriteExistentialType(node.expression, existentialTypes: existentialTypes)
        let newNode = node.with(\.expression, newExpression)
        return ExprSyntax(newNode)
    }

    override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
        let newExpression = rewriteExistentialType(node.expression, existentialTypes: existentialTypes)
        let newNode = node.with(\.expression, newExpression)
        return ExprSyntax(newNode)
    }
}

func rewriteExistentialType<S: SyntaxProtocol>(_ node: S, existentialTypes: Set<String>) -> S {
    return ExistentialTypeRewriter(existentialTypes: existentialTypes).rewrite(node).as(S.self)!
}
