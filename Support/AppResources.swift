import Foundation

enum AppResources {
    static var bundle: Bundle {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("PhotoStudio_PhotoStudio.bundle"),
           let bundle = Bundle(url: url) { return bundle }
        return .module
    }
}
