import Foundation



public enum SafeGlobalMacrosError : Error {
	
	case appliedToNonVariable
	case appliedToNonIdentifierVariable
	
	case internalError
	
}
typealias Err = SafeGlobalMacrosError
