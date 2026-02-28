import CoreText
import CoreGraphics
import Foundation

@MainActor
struct FontManager {
    static func registerFonts() {
        guard let resourceURL = Bundle.main.resourceURL else {
            print("FontManager: Could not find bundle resource URL")
            return
        }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            print("FontManager: Could not enumerate bundle resources")
            return
        }

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard ext == "ttf" || ext == "otf" else { continue }

            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(
                fileURL as CFURL,
                .process,
                &errorRef
            )

            if success {
                print("FontManager: Registered font \(fileURL.lastPathComponent)")
            } else {
                let error = errorRef?.takeRetainedValue()
                print("FontManager: Failed to register font \(fileURL.lastPathComponent) - \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
}
