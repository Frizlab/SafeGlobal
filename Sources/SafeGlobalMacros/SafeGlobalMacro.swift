import Foundation

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros



/**
 Implementation of the `stringify` macro, which takes an expression of any type and produces a tuple containing the value of that expression and the source code that produced the value.
 
 For example
 
     #stringify(x + y)
 
 will expand to
 
     (x + y, "x + y") */
public struct SafeGlobalMacro : PeerMacro, AccessorMacro {
	
	struct NotImplemented : Error {}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard var variables = declaration.as(VariableDeclSyntax.self) else {
			throw Err.appliedToNonVariable
		}
		/* Add the _ prefix to the variable(s) name(s). */
		variables.bindings = try PatternBindingListSyntax(variables.bindings.children(viewMode: .all).map{ binding in
			guard var binding = binding.as(PatternBindingSyntax.self) else {
				throw Err.internalError
			}
			guard var pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
				throw Err.appliedToNonIdentifierVariable
			}
			pattern.identifier = "_\(raw: pattern.identifier.text)"
			binding.pattern = PatternSyntax(pattern)
			return binding
		})
		/* Remove the @SafeGlobal annotation. */
		variables.attributes = variables.attributes.filter{ attribute in
			return (attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text != "SafeGlobal")
		}
		return [DeclSyntax(variables)]
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		return []
	}
	
}


@main
struct SafeGlobalPlugin : CompilerPlugin {
	
	let providingMacros: [Macro.Type] = [
		SafeGlobalMacro.self,
	]
	
}
