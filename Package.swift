// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "EssentialFeed",
	platforms: [
		.iOS(.v16),
		.macOS(.v13),
		.macCatalyst(.v16),
		.tvOS(.v16),
		.watchOS(.v9)
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "EssentialFeed",
			targets: ["EssentialFeed"]),
		.library(
			name: "EssentialFeedTestHelpers",
			targets: ["EssentialFeedTestHelpers"]),
	],
	dependencies: [],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "EssentialFeed",
			dependencies: []),
		.target(
			name: "EssentialFeedTestHelpers",
			dependencies: []),
		.testTarget(
			name: "EssentialFeedTests",
			dependencies: ["EssentialFeed", "EssentialFeedTestHelpers"]),
		.testTarget(
			name: "EssentialFeedAPIEndToEndTests",
			dependencies: ["EssentialFeed", "EssentialFeedTestHelpers"]),
	]
)
