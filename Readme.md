# SafeGlobal
A macro to have concurrency-safe globals (e.g. a static variable on an enum) in Swift 5.10.

## Usage
Add this package in your `Package.swift` file and trust it.

Then import `SafeGlobal` and prefix your global variables with `@SafeGlobal`.
Here’s an example:
```swift
import SafeGlobal

public enum Conf : Sendable {
   
   @SafeGlobal public static var apiURL: URL = URL(string: "…")!
   
}
```

## Why?
With Swift 5.9, globals were deemed (rightly) non-concurrent-safe.
A common workaround was to create a property wrapper which added a lock around the access/modification of the global.

This workaround was great and easy to implement, but does not work anymore with Swift 5.10.
The reason for this is related to the property wrapper implementation, but I did not grasp the intricacy of the reasons fully,
 so I’m not gonna elaborate on this.

Anyway, by basically reimplementing the property wrapper using a macro we get rid of the warnings once again!

Here are the relevant threads in the Swift forum:
- <https://forums.swift.org/t/70116>
- <https://forums.swift.org/t/58088/20>
