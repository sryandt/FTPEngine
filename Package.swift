// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FTPEngine",
	 platforms: [
				 .macOS(.v11),
				 .iOS(.v15),
				 .watchOS(.v7)
		  ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			 name: "FTPEngine",
			 targets: ["FTPEngine"]),

			.library(
				 name: "FTPSwift",
				 targets: ["FTPSwift"]),
	 ],
	 dependencies: [
		.package(url: "https://github.com/ios-tooling/Suite", .upToNextMajor(from: "1.0.135")),
	 ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
		.target(
			 name: "FTPSwift", dependencies: ["FTPEngine", .product(name: "Suite", package: "Suite")], publicHeadersPath: "Include"),
		.target(
			 name: "FTPEngine", publicHeadersPath: "Include"),
        .testTarget(
            name: "FTPEngineTests",
            dependencies: ["FTPEngine"]),
    ]
)
