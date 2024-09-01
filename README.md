# ExistentialAnyRefactor
A refactoring tool to assist with the transition to Swift 6 by handling the conversion to `ExistentialAny`.

# Feature
- This tool scans the specified Swift files for protocols and automatically adds the `any` keyword to all instances where those protocols are used.

```swift
// Before
protocol P {}

class C {
    let p: P?
    func f(p: P) -> P
    func f2(f: () -> P?) -> Result<P, E>
}
```

```swift
// After
protocol P {}

class C {
    let p: (any P)?
    func f(p: any P) -> any P
    func f2(f: () -> (any P)?) -> Result<any P, E>
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
