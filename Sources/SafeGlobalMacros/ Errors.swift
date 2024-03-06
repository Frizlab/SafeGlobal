import Foundation



public enum SafeGlobalMacroError : Error {
	
	case appliedToNonVariable
	case appliedToNonIdentifierVariable
	
	case internalError
	
}
typealias Err = SafeGlobalMacroError
