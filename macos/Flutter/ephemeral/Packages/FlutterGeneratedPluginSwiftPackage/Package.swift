// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "file_picker_darwin", path: "../.packages/file_picker_darwin-1.0.0"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.0"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.0"),
        .package(name: "open_file_mac", path: "../.packages/open_file_mac-1.1.0"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "file-picker-darwin", package: "file_picker_darwin"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "open-file-mac", package: "open_file_mac"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
