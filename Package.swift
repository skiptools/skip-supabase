// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription
import Foundation

let package = Package(
    name: "skip-supabase",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipSupabase", targets: ["SkipSupabase"]),
        .library(name: "SkipSupabaseCore", targets: ["SkipSupabaseCore"]),
        .library(name: "SkipSupabaseAuth", targets: ["SkipSupabaseAuth"]),
        .library(name: "SkipSupabaseFunctions", targets: ["SkipSupabaseFunctions"]),
        .library(name: "SkipSupabasePostgREST", targets: ["SkipSupabasePostgREST"]),
        .library(name: "SkipSupabaseRealtime", targets: ["SkipSupabaseRealtime"]),
        .library(name: "SkipSupabaseStorage", targets: ["SkipSupabaseStorage"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.20.3")
    ],
    targets: [
        .target(name: "SkipSupabaseCore", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabaseAuth", dependencies: [
            .product(name: "Auth", package: "supabase-swift"),
            "SkipSupabaseCore"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabaseAuthTests", dependencies: [
            "SkipSupabaseAuth",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabaseFunctions", dependencies: [
            .product(name: "Functions", package: "supabase-swift"),
            "SkipSupabaseCore"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabaseFunctionsTests", dependencies: [
            "SkipSupabaseFunctions", .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabasePostgREST", dependencies: [
            .product(name: "PostgREST", package: "supabase-swift"),
            "SkipSupabaseCore"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabasePostgRESTTests", dependencies: [
            "SkipSupabasePostgREST",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabaseRealtime", dependencies: [
            .product(name: "Realtime", package: "supabase-swift"),
            "SkipSupabaseCore"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabaseRealtimeTests", dependencies: [
            "SkipSupabaseRealtime",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabaseStorage", dependencies: [
            .product(name: "Storage", package: "supabase-swift"),
            "SkipSupabaseCore"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabaseStorageTests", dependencies: [
            "SkipSupabaseStorage",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipSupabase", dependencies: [
            .product(name: "Supabase", package: "supabase-swift"),
            "SkipSupabaseAuth",
            "SkipSupabaseFunctions",
            "SkipSupabasePostgREST",
            "SkipSupabaseRealtime",
            "SkipSupabaseStorage"
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipSupabaseTests", dependencies: [
            "SkipSupabase",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [Target.PluginUsage.plugin(name: "skipstone", package: "skip")]),
    ]
)
