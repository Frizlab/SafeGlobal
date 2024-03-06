import Foundation

import SafeGlobal



enum Conf : Sendable {
	
	@SafeGlobal static let dummy1: Int = 42
	@SafeGlobal static var dummy2: Int = 42
	@SafeGlobal static var dummy3: Int!
	@SafeGlobal static var dummy4: Int?
	@SafeGlobal static var dummy5: Int? = nil
	
}
