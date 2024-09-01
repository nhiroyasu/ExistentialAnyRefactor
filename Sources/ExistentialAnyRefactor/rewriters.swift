import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Rewrite the syntax tree to add `any` keyword.

func refactor(_ node: TypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    if let identifierType = node.as(IdentifierTypeSyntax.self) {
        let anyType = refactor(identifierType, existentialTypes: existentialTypes)
        return anyType
    } else if let optionalType = node.as(OptionalTypeSyntax.self) {
        let anyType = refactor(optionalType, existentialTypes: existentialTypes)
        return anyType
    } else if let implicitlyUnwrappedOptionalType = node.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
        let anyType = refactor(implicitlyUnwrappedOptionalType, existentialTypes: existentialTypes)
        return anyType
    } else if let compositionType = node.as(CompositionTypeSyntax.self) {
        let anyType = refactor(compositionType, existentialTypes: existentialTypes)
        return anyType
    } else if let functionType = node.as(FunctionTypeSyntax.self) {
        let anyType = refactor(functionType, existentialTypes: existentialTypes)
        return anyType
    } else if let attributedTypeSyntax = node.as(AttributedTypeSyntax.self) {
        let newBaseType = refactor(attributedTypeSyntax.baseType, existentialTypes: existentialTypes)
        let newAttributedTypeSyntax = attributedTypeSyntax.with(\.baseType, newBaseType)
        return TypeSyntax(newAttributedTypeSyntax)
    } else if let tupleType = node.as(TupleTypeSyntax.self) {
        var mutableTupleTypes: [TupleTypeElementSyntax] = []
        tupleType.elements.forEach { element in
            let anyType = refactor(element.type, existentialTypes: existentialTypes)
            let newElement = element.with(\.type, anyType)
            mutableTupleTypes.append(newElement)
        }
        let newTupleType = tupleType.with(\.elements, TupleTypeElementListBuilder.buildFinalResult(
            TupleTypeElementListBuilder.buildBlock(mutableTupleTypes)
        ))
        return TypeSyntax(newTupleType)
    } else if let arrayType = node.as(ArrayTypeSyntax.self) {
        let anyType = refactor(arrayType.element, existentialTypes: existentialTypes)
        let newArrayType = arrayType.with(\.element, anyType)
        return TypeSyntax(newArrayType)
    } else if let dictType = node.as(DictionaryTypeSyntax.self) {
        let anyValueType = refactor(dictType.value, existentialTypes: existentialTypes)
        let newDictType = dictType.with(\.value, anyValueType)
        return TypeSyntax(newDictType)
    } else if let memberType = node.as(MemberTypeSyntax.self) {
        let anyType = refactor(memberType, existentialTypes: existentialTypes)
        return anyType
    } else {
        return node
    }
}

/// Rewrite the identifier type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let a: A
/// ```
/// After
/// ```swift
/// let a: any A
/// ```
///
/// - Parameter node: IdentifierTypeSyntax
/// - Returns: TypeSyntax
func refactor(_ node: IdentifierTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    if existentialTypes.contains(node.name.text) {
        let anySyntax = SomeOrAnyTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
            constraint: node.trimmed,
            trailingTrivia: node.trailingTrivia
        )
        return TypeSyntax(anySyntax)
    }

    if let genericArgumentClause = node.genericArgumentClause {
        var newGenericArguments: [GenericArgumentSyntax] = []
        for i in 0..<genericArgumentClause.arguments.count {
            let argument = genericArgumentClause.arguments[genericArgumentClause.arguments.index(at: i)]
            let anyType = refactor(argument.argument, existentialTypes: existentialTypes)
            let newArgument = argument.with(\.argument, anyType)
            newGenericArguments.append(newArgument)
        }
        let newGenericArgumentClause = genericArgumentClause.with(\.arguments, GenericArgumentListBuilder.buildFinalResult(
            GenericArgumentListBuilder.buildBlock(newGenericArguments)
        ))
        let newGenericType = node.with(\.genericArgumentClause, newGenericArgumentClause)
        return TypeSyntax(newGenericType)
    }

    return TypeSyntax(node)
}

/// Rewrite the member type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let a: A.B
/// ```
/// After
/// ```swift
/// let a: any A.B
/// ```
///
/// - Parameter node: IdentifierTypeSyntax
/// - Returns: TypeSyntax
func refactor(_ node: MemberTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    // FIXME: MemberTypeSyntax is not supported refactoring for existential types yet.
//        if existentialTypes.contains(node.name.text) {
//            let anySyntax = SomeOrAnyTypeSyntax(
//                leadingTrivia: node.leadingTrivia,
//                someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
//                constraint: node.trimmed,
//                trailingTrivia: node.trailingTrivia
//            )
//            return TypeSyntax(anySyntax)
//        }

    if let genericArgumentClause = node.genericArgumentClause {
        var newGenericArguments: [GenericArgumentSyntax] = []
        for i in 0..<genericArgumentClause.arguments.count {
            let argument = genericArgumentClause.arguments[genericArgumentClause.arguments.index(at: i)]
            let anyType = refactor(argument.argument, existentialTypes: existentialTypes)
            let newArgument = argument.with(\.argument, anyType)
            newGenericArguments.append(newArgument)
        }
        let newGenericArgumentClause = genericArgumentClause.with(\.arguments, GenericArgumentListBuilder.buildFinalResult(
            GenericArgumentListBuilder.buildBlock(newGenericArguments)
        ))
        let newGenericType = node.with(\.genericArgumentClause, newGenericArgumentClause)
        return TypeSyntax(newGenericType)
    }

    return TypeSyntax(node)
}

/// Rewrite the optional type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let a: A?
/// let ab: (A & B)?
/// ```
/// After
/// ```swift
/// let a: (any A)?
/// let ab: (any A & B)?
/// ```
///
/// - Parameter node: OptionalTypeSyntax
/// - Returns: TypeSyntax
func refactor(_ node: OptionalTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    if let typeSyntax = node.wrappedType.as(IdentifierTypeSyntax.self),
       existentialTypes.contains(typeSyntax.name.text) {
        let anyType = SomeOrAnyTypeSyntax(
            leadingTrivia: typeSyntax.leadingTrivia,
            someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
            constraint: typeSyntax,
            trailingTrivia: typeSyntax.trailingTrivia
        )
        let tupleTypeSyntax = TupleTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            elements: TupleTypeElementListBuilder.buildFinalResult(
                TupleTypeElementListBuilder.buildBlock([TupleTypeElementSyntax(type: anyType)])
            )
        )
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(tupleTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let tupleTypeSyntax = node.wrappedType.as(TupleTypeSyntax.self),
       let compositionTypeSyntax = tupleTypeSyntax.elements.first?.type.as(CompositionTypeSyntax.self),
       compositionTypeSyntax.elements
        .compactMap({ $0.type.as(IdentifierTypeSyntax.self)?.name.text })
        .contains(where: { existentialTypes.contains($0) }) {
        let anyType = refactor(compositionTypeSyntax, existentialTypes: existentialTypes)
        let newTupleTypeSyntax = TupleTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            elements: TupleTypeElementListBuilder.buildFinalResult(
                TupleTypeElementListBuilder.buildBlock([TupleTypeElementSyntax(type: anyType)])
            )
        )
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newTupleTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let arrayTypeSyntax = node.wrappedType.as(ArrayTypeSyntax.self) {
        let newArrayTypeSyntax = refactor(TypeSyntax(arrayTypeSyntax), existentialTypes: existentialTypes)
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newArrayTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let dictTypeSyntax = node.wrappedType.as(DictionaryTypeSyntax.self) {
        let newDictTypeSyntax = refactor(TypeSyntax(dictTypeSyntax), existentialTypes: existentialTypes)
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newDictTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else {
        return TypeSyntax(node)
    }
}

/// Rewrite the implicitly unwrapped optional type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let a: A!
/// let ab: (A & B)!
/// ```
/// After
/// ```swift
/// let a: (any A)!
/// let ab: (any A & B)!
/// ```
///
/// - Parameter node: ImplicitlyUnwrappedOptionalTypeSyntax
/// - Returns: TypeSyntax
func refactor(_ node: ImplicitlyUnwrappedOptionalTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    if let typeSyntax = node.wrappedType.as(IdentifierTypeSyntax.self),
       existentialTypes.contains(typeSyntax.name.text) {
        let anyType = SomeOrAnyTypeSyntax(
            leadingTrivia: typeSyntax.leadingTrivia,
            someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
            constraint: typeSyntax,
            trailingTrivia: typeSyntax.trailingTrivia
        )
        let tupleTypeSyntax = TupleTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            elements: TupleTypeElementListBuilder.buildFinalResult(
                TupleTypeElementListBuilder.buildBlock([TupleTypeElementSyntax(type: anyType)])
            )
        )
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(tupleTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let tupleTypeSyntax = node.wrappedType.as(TupleTypeSyntax.self),
       let compositionTypeSyntax = tupleTypeSyntax.elements.first?.type.as(CompositionTypeSyntax.self),
       compositionTypeSyntax.elements
        .compactMap({ $0.type.as(IdentifierTypeSyntax.self)?.name.text })
        .contains(where: { existentialTypes.contains($0) }) {
        let anyType = refactor(compositionTypeSyntax, existentialTypes: existentialTypes)
        let newTupleTypeSyntax = TupleTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            elements: TupleTypeElementListBuilder.buildFinalResult(
                TupleTypeElementListBuilder.buildBlock([TupleTypeElementSyntax(type: anyType)])
            )
        )
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newTupleTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let arrayTypeSyntax = node.wrappedType.as(ArrayTypeSyntax.self) {
        let newArrayTypeSyntax = refactor(TypeSyntax(arrayTypeSyntax), existentialTypes: existentialTypes)
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newArrayTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else if let dictTypeSyntax = node.wrappedType.as(DictionaryTypeSyntax.self) {
        let newDictTypeSyntax = refactor(TypeSyntax(dictTypeSyntax), existentialTypes: existentialTypes)
        let newOptionalSyntax = node.with(\.wrappedType, TypeSyntax(newDictTypeSyntax))
        return TypeSyntax(newOptionalSyntax)
    } else {
        return TypeSyntax(node)
    }
}

/// Rewrite the composition type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let ab: A & B
/// ```
/// After
/// ```swift
/// let ab: any A & B
/// ```
///
/// - Parameter node: CompositionTypeSyntax
/// - Returns: TypeSyntax
func refactor(_ node: CompositionTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    let containsExistentialType = node.elements
        .compactMap({ $0.type.as(IdentifierTypeSyntax.self)?.name.text })
        .contains(where: { existentialTypes.contains($0) })
    if containsExistentialType {
        let anyType = SomeOrAnyTypeSyntax(
            leadingTrivia: node.leadingTrivia,
            someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, [.spaces(1)]),
            constraint: node.trimmed,
            trailingTrivia: node.trailingTrivia
        )
        return TypeSyntax(anyType)
    }

    return TypeSyntax(node)
}

/// Rewrite the function type with `any` keyword.
///
/// # Example
/// Before
/// ```swift
/// let a: (A) -> B
/// ```
/// After
/// ```swift
/// let a: (any A) -> any B
/// ```
///
/// - Parameters:
///   - node: FunctionTypeSyntax
///   - existentialTypes: Set<String>
/// - Returns: TypeSyntax
func refactor(_ node: FunctionTypeSyntax, existentialTypes: Set<String>) -> TypeSyntax {
    var mutableNode = node
    var tupleTypesList: [TupleTypeElementSyntax] = []
    for i in 0..<node.parameters.count {
        let parameter = node.parameters[node.parameters.index(at: i)]
        let anyType = refactor(parameter.type, existentialTypes: existentialTypes)
        let newTupleTypeElement = parameter.with(\.type, anyType)
        tupleTypesList.append(newTupleTypeElement)
    }
    let tupleTypeElementList = TupleTypeElementListBuilder.buildFinalResult(
        TupleTypeElementListBuilder.buildBlock(tupleTypesList)
    )
    mutableNode = mutableNode.with(\.parameters, tupleTypeElementList)

    let anyType = refactor(node.returnClause.type, existentialTypes: existentialTypes)
    let newReturnClause = node.returnClause.with(\.type, anyType)
    mutableNode = mutableNode.with(\.returnClause, newReturnClause)

    return TypeSyntax(mutableNode)
}
