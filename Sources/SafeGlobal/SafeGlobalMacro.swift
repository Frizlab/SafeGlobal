import Foundation



@attached(accessor)
@attached(peer, names: prefixed(_))
public macro SafeGlobal() = #externalMacro(module: "SafeGlobalMacros", type: "SafeGlobalMacro")
