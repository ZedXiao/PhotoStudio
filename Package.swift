// swift-tools-version: 6.0
import PackageDescription
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
let package = Package(
    name: "PhotoStudio",
    platforms: [.macOS("26.0")],
    products: [.executable(name: "PhotoStudio", targets: ["PhotoStudio"]),
               .executable(name: "PhotoStudioProbe", targets: ["PhotoStudioProbe"])],
    targets: [
        .target(name: "LibRaw", path: "Vendor/LibRaw-0.22.3",
                exclude: ["src/postprocessing/postprocessing_ph.cpp", "src/preprocessing/preprocessing_ph.cpp", "src/write/write_ph.cpp", "src/Makefile"],
                sources: ["src"], publicHeadersPath: "libraw",
                cxxSettings: [.headerSearchPath("."), .define("LIBRAW_NODLL"),
                              .define("USE_ZLIB"), .unsafeFlags(["-O2"])],
                linkerSettings: [.linkedLibrary("c++"), .linkedLibrary("z")]),
        .target(name: "CLibRawBridge", dependencies: ["LibRaw"], publicHeadersPath: "include",
                cxxSettings: [.unsafeFlags(["-I\(root)/Vendor/LibRaw-0.22.3"])]),
        .target(name: "PhotoStudioCore", dependencies: ["CLibRawBridge"]),
        .executableTarget(name: "PhotoStudio", dependencies: ["PhotoStudioCore"], path: ".",
                          exclude: ["Sources", "Tests", "Vendor", "script", "dist", "README.md", "README.en.md", "Docs", ".codex", ".gitignore", "Package.swift"],
                          sources: ["App", "Views", "Models", "Stores", "Services", "Support"],
                          resources: [.copy("Resources")]),
        .executableTarget(name: "PhotoStudioProbe", dependencies: ["PhotoStudioCore"]),
        .testTarget(name: "PhotoStudioCoreTests", dependencies: ["PhotoStudioCore"])
    ],
    swiftLanguageModes: [.v5],
    cxxLanguageStandard: .cxx17
)
