import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

public class Refactor {
    let existentialTypes: Set<String>

    public init(existentialTypes: Set<String>) {
        self.existentialTypes = existentialTypes
    }

    public func exec(_ source: String) -> String {
        let syntax = Parser.parse(source: source)
        let newSyntax = rootRewriter(syntax, existentialTypes: existentialTypes)
        return newSyntax.description
    }
}
