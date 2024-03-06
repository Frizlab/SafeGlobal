import Foundation

/* Inspiration from <https://forums.swift.org/t/static-property-wrappers-and-strict-concurrency-in-5-10/70116/15>. */


//@propertyWrapper
public class SafeGlobal<T : Sendable> : @unchecked Sendable {
	
	public var wrappedValue: T {
		get {safeGlobalLock.withLock{ _wrappedValue }}
		set {safeGlobalLock.withLock{ _wrappedValue = newValue }}
	}
	
	public init(wrappedValue: T) {
		self._wrappedValue = wrappedValue
	}
	
	public init<V>() where T == Optional<V> {
		self._wrappedValue = nil
	}
	
	private var _wrappedValue: T
	
}


@attached(accessor)
@attached(peer, names: prefixed(_))
public macro SafeGlobal() = #externalMacro(module: "SafeGlobalMacros", type: "SafeGlobalMacro")


/* We use the same lock for all SafeGlobal instances.
 * We could use one lock per instance instead but there’s no need AFAICT.
 * We do not use OSAllocatedUnfairLock because it’s not Linuxy. */
private let safeGlobalLock = NSLock()
