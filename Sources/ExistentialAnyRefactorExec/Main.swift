import Foundation
import ExistentialAnyRefactor
import ExistentialTypeRetriever
import Util

@main
class Main {
    static func main() {
        guard CommandLine.arguments.count > 1 else {
            print("⛔️ To execute the command, the following arguments are required.")
            print("Usage: existential-any-refactor <target-paths> [--obvious_existential_types <types>]")
            return
        }

        let commandArguments = parse(args: Array(CommandLine.arguments.dropFirst()))

        let fileService = FileService()
        let swiftFiles: Set<String> = commandArguments
            .targetPaths
            .map { fileService.findSwiftFiles(in: $0) }
            .reduce(Set<String>(), { $0.union($1) })
        printColoredText("✅ \(swiftFiles.count) swift files were found.", colorCode: "32")

        printColoredText("Retrieving existential types...", colorCode: "33")
        var existentialTypes: Set<String> = [
            // Obvious existential types
            "Decoder",
            "Encoder",
            "NSObjectProtocol"
        ]
        existentialTypes.formUnion(commandArguments.obviousExistentialTypes)
        
        let existentialTypeRetriever = Retriever()
        for (index, file) in swiftFiles.enumerated() {
            do {
                let source = try String(contentsOfFile: file)
                let addingExistentialTypes = existentialTypeRetriever.retrieve(source: source)
                existentialTypes.formUnion(addingExistentialTypes)
                if index > 0 {
                    print("\u{1B}[1A\u{1B}[K", terminator: "")
                }
                print("[\(index + 1)/\(swiftFiles.count)] Retrieving existential types")
            } catch {
                print("⛔ Error:", error, "at: \(file)")
            }
        }
        printColoredText("✅ \(existentialTypes.count) existential types were retrieved.", colorCode: "32")

        printColoredText("Refactoring...", colorCode: "33")
        let refactor = Refactor(existentialTypes: existentialTypes)
        for (index, file) in swiftFiles.enumerated() {
            do {
                let source = try String(contentsOfFile: file)
                let newSource = refactor.exec(source)
                try fileService.write(source: newSource, at: file)
                if index > 0 {
                    print("\u{1B}[1A\u{1B}[K", terminator: "")
                }
                print("[\(index + 1)/\(swiftFiles.count)] Refactoring existential types")
            } catch {
                print("⛔ Error:", error, "at: \(file)")
            }
        }
        printColoredText("✅ Refactoring was completed.", colorCode: "32")
    }
}
