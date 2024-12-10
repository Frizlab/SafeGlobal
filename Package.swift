// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport


let package = Package(
	name: "SafeGlobal",
	platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
	products: [
		.library(name: "SafeGlobal", targets: ["SafeGlobal"]),
	],
	dependencies: [
		/* TODO: CI should test the package w/ all of the major versions we support of swift-syntax specified explicitly. */
		.package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"601.0.0"),
//		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
//		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0"),
//		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "509.0.0"),
	],
	targets: [
		/* Macro implementation that performs the source transformation of a macro. */
		.macro(
			name: "SafeGlobalMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
			]
		),
		
		/* Library that exposes a macro as part of its API, which is used in client programs. */
		.target(name: "SafeGlobal", dependencies: ["SafeGlobalMacros"]),
		
		/* A client of the library, which is able to use the macro in its own code. */
		.executableTarget(name: "SafeGlobalClient", dependencies: ["SafeGlobal"]),
		
		/* A test target used to develop the macro implementation. */
		.testTarget(
			name: "SafeGlobalTests",
			dependencies: [
				"SafeGlobalMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
	]
)
