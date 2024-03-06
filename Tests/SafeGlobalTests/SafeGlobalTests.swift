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
	
	func testMacro() throws {
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
				
					static var _dummy: Int = 42
				}
				""",
			macros: testMacros
		)
#else
		throw XCTSkip("Macros are only supported when running tests for the host platform.")
#endif
	}
	
}
