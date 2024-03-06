import Foundation

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros



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
				let type = if let implicitlyUnwrappedType = typeAnnotation.type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
					TypeSyntax(OptionalTypeSyntax(wrappedType: implicitlyUnwrappedType.wrappedType))
				} else {
					typeAnnotation.type
				}
				typeAnnotation.type = "SafeGlobal<\(type.trimmed)>"
				binding.typeAnnotation = typeAnnotation
			}
			/* Set the variable initial value if present. */
			if var initializer = binding.initializer {
				initializer.value = "SafeGlobal(wrappedValue: \(initializer.value))"
				binding.initializer = initializer
			} else {
				binding.initializer = InitializerClauseSyntax(value: "SafeGlobal()" as ExprSyntax)
			}
			return binding
		})
		/* Remove the @SafeGlobal annotation. */
		variables.attributes = variables.attributes.filter{ attribute in
			return (attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text != "SafeGlobal")
		}
		/* Force the variable to be a constant (the wrapper will never have to change). */
		variables.bindingSpecifier = "let"
		/* Set the variable as private. */
		variables.modifiers = variables.modifiers.filter{ modifier in
			let name = modifier.trimmed.name.text
			/* Full list as of swift-syntax 510.0.0:
			 *  (`'__consuming'` | `'__setter_access'` | `'_const'` | `'_local'` | `'actor'` | `'async'` | `'borrowing'` |
			 *   `'class'` | `'consuming'` | `'convenience'` | `'distributed'` | `'dynamic'` | `'fileprivate'` | `'final'` |
			 *   `'indirect'` | `'infix'` | `'internal'` | `'isolated'` | `'lazy'` | `'mutating'` | `'nonisolated'` | `'nonmutating'` |
			 *   `'open'` | `'optional'` | `'override'` | `'package'` | `'postfix'` | `'prefix'` | `'private'` | `'public'` | `'reasync'` |
			 *   `'required'` | `'static'` | `'unowned'` | `'weak'`)
			 * The list can be found in the documentation of `DeclModifierSyntax`.
			 * There are probably a bunch of modifiers where we should have specific actions, but for now we’ll let it be. */
			let removedModifiers: Set<String> = ["public", "internal", "fileprivate", "private"]
			let knownModifiers: Set<String> = removedModifiers.union(["static"])
			if !knownModifiers.contains(name) {
				context.diagnose(
					Diagnostic(
						node: Syntax(modifier),
						message: SimpleDiagnosticMessage(
							message: "Ignored modifier “\(name)”. The author of SafeGlobal does not have time to do everything :)",
							diagnosticID: MessageID(domain: "SafeGlobal", id: "UnknownModifier"),
							severity: .warning
						)
					)
				)
			}
			return !removedModifiers.contains(name)
		}
		variables.modifiers.insert(.init(name: "private"), at: variables.modifiers.startIndex)
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
