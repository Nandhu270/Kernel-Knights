// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LabRecordBook",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "LabRecordBook", targets: ["LabRecordBook"])
    ],
    targets: [
        .target(
            name: "LabRecordBook",
            path: "LabRecordBook",
            exclude: ["Info.plist"]
        )
    ]
)
