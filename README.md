# ExistentialAnyRefactor
A refactoring tool to assist with the transition to Swift 6 by handling the conversion to `ExistentialAny`.

# Feature
- This tool scans the specified Swift files for protocols and automatically adds the `any` keyword to all instances where those protocols are used.

```swift
// Before
protocol P {}

class C {
    let p: P
    let p2: [P]
    let p3: [Int: P]
    let p4: P & Q
    func f(p: P) -> P
}
```

```swift
// After
protocol P {}

class C {
    let p: any P
    let p2: [any P]
    let p3: [Int: any P]
    let p4: any P & Q
    func f(p: any P) -> any P
}
```

## Warning
- Not all protocols can have `any` applied to them. Types defined within the SDK cannot be scanned, and therefore may not be refactored.
- In cases where the code is complex, the `any` keyword might not be applicable. Please consider this tool as a support tool for your refactoring process.

# Usage
```shell
$ swift build -c release
$ ./.build/release/existential-any-refactor <target-paths> [--obvious_existential_types <types>]
```
