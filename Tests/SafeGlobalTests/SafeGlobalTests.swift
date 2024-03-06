import XCTest

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport



/* Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
 * Cross-compiled tests may still make use of the macro itself in end-to-end tests. */
#if canImport(SafeGlobalMacros)
import SafeGlobalMacros

let testMacros: [String: Macro.Type] = [
	"SafeGlobal": SafeGlobalMacro.self,
]
#endif


final class SafeGlobalTests : XCTestCase {
	
	func testMacroFullVar() throws {
#if canImport(SafeGlobalMacros)
		assertMacroExpansion("""
				enum Conf : Sendable {
					@SafeGlobal static var dummy: Int = 42
				}
				""",
			expandedSource: """
				enum Conf : Sendable {
					static var dummy: Int {
					    get {
					        _dummy.wrappedValue
					    }
					    set {
					        _dummy.wrappedValue = newValue
					    }
					}
				
					private static let _dummy: SafeGlobal<Int> = SafeGlobal(wrappedValue: 42)
				}
				""",
			macros: testMacros
		)
#else
		throw XCTSkip("Macros are only supported when running tests for the host platform.")
#endif
	}
	
	func testMacroFullLet() throws {
#if canImport(SafeGlobalMacros)
		/* Apparently the computed let property is ok for the compiler? Weird… */
		assertMacroExpansion("""
				enum Conf : Sendable {
					@SafeGlobal static let dummy: Int = 42
				}
				""",
			expandedSource: """
				enum Conf : Sendable {
					static let dummy: Int {
					    get {
					        _dummy.wrappedValue
					    }
					}
				
					private static let _dummy: SafeGlobal<Int> = SafeGlobal(wrappedValue: 42)
				}
				""",
			macros: testMacros
		)
#else
		throw XCTSkip("Macros are only supported when running tests for the host platform.")
#endif
	}
	
}
