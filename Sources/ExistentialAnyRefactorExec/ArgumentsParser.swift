import Foundation

struct CommandArguments {
    let targetPaths: Set<String>
    let obviousExistentialTypes: Set<String>
}

func parse(args: [String]) -> CommandArguments {
    var targetPaths: [String] = []
    var obviousExistentialTypes: [String] = []
    for (index, arg) in args.enumerated() {
        if arg == "--obvious_existential_types" {
            obviousExistentialTypes = Array(args[(index + 1)...])
            break
        }
        targetPaths.append(arg)
    }
    return CommandArguments(
        targetPaths: Set(targetPaths),
        obviousExistentialTypes: Set(obviousExistentialTypes)
    )
}
