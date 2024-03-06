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
		/* We apply the variable transformations for all the variables but
		 *  we could guard there is only one as a peer macro can only be applied to a single variable. */
		variables.bindings = try PatternBindingListSyntax(variables.bindings.children(viewMode: .all).map{ binding in
			guard var binding = binding.as(PatternBindingSyntax.self) else {
				throw Err.internalError
			}
			/* Add the _ prefix to the variable name. */
			guard var pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
				throw Err.appliedToNonIdentifierVariable
			}
			pattern.identifier = "_\(raw: pattern.identifier.text)"
			binding.pattern = PatternSyntax(pattern)
			/* Set the variable type if present. */
			if var typeAnnotation = binding.typeAnnotation {
				typeAnnotation.type = "SafeGlobal<\(typeAnnotation.type.trimmed)>"
				binding.typeAnnotation = typeAnnotation
			}
			/* Change the variable initial value if present. */
			if var initializer = binding.initializer {
				initializer.value = "SafeGlobal(wrappedValue: \(initializer.value))"
				binding.initializer = initializer
			}
			return binding
		})
		/* Remove the @SafeGlobal annotation. */
		variables.attributes = variables.attributes.filter{ attribute in
			return (attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text != "SafeGlobal")
		}
		variables.bindingSpecifier = "let"
		return [DeclSyntax(variables)]
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		guard let variable = declaration.as(VariableDeclSyntax.self) else {
			throw Err.appliedToNonVariable
		}
		guard let binding = variable.bindings.first, variable.bindings.count == 1,
				let patternName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
		else {
			/* The variable must have 1 binding exactly as accessor macro can only be applied on single variables. */
			throw Err.internalError
		}
		let underscore = "_" + patternName
		return (
			                                                   ["get {\(raw: underscore).wrappedValue}"] +
			(variable.bindingSpecifier.trimmed.text == "var" ? ["set {\(raw: underscore).wrappedValue = newValue}"] : [])
		)
	}
	
}


@main
struct SafeGlobalPlugin : CompilerPlugin {
	
	let providingMacros: [Macro.Type] = [
		SafeGlobalMacro.self,
	]
	
}
