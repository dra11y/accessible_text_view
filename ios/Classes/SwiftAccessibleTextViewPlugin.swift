import Flutter
import UIKit

public class SwiftAccessibleTextViewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {

        FontRegistry.registerFonts(registrar: registrar)

        let factory = AccessibleTextViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.dra11y.flutter/accessible_text_view")
    }
}

struct FontManifestEntry: Decodable {
    let family: String
    let fonts: [Asset]

    struct Asset: Decodable {
        let asset: String
    }
}

public class FontRegistry {
    public static func resolve(family: String?, size: CGFloat?) -> UIFont? {
        let size = size ?? UIFont.systemFontSize
        guard
            let family = family,
            let fontFamily = registeredFonts[family]
        else {
            return UIFont.systemFont(ofSize: size)
        }
        return UIFont(name: fontFamily, size: size)
    }

    fileprivate static func register(family: String, fontName: String) {
        registeredFonts[family] = fontName
    }

    private static var registeredFonts = [String : String]()

    fileprivate static func registerFonts(registrar: FlutterPluginRegistrar) {
        guard
            let manifestUrl = Bundle.main.url(forResource: registrar.lookupKey(forAsset: "FontManifest"), withExtension: "json"),
            let manifestData = try? Data(contentsOf: manifestUrl, options: .mappedIfSafe),
            let manifest = try? JSONDecoder().decode([FontManifestEntry].self, from: manifestData)
        else {
            fatalError("Could not read FontManifest.json!")
        }

        manifest.forEach { manifestEntry in
            let family = NSString(string: manifestEntry.family).lastPathComponent
            manifestEntry.fonts.forEach { fontAsset in
                let assetKey = registrar.lookupKey(forAsset: fontAsset.asset)
                let fontName = NSString(string: NSString(string: fontAsset.asset).lastPathComponent).deletingPathExtension

                var error: Unmanaged<CFError>? = nil

                guard
                    let fontUrl = Bundle.main.url(forResource: assetKey, withExtension: nil),
                    let data = try? Data(contentsOf: fontUrl),
                    let provider = CGDataProvider(data: data as CFData),
                    let cgFont = CGFont(provider),
                    CTFontManagerRegisterGraphicsFont(cgFont, &error),
                    UIFont(name: fontName, size: 24) != nil
                else {
//                    assertionFailure("Could not register font family: \(family) with asset path: \(fontAsset.asset). ERROR: \(String(describing: error))\nFONT MANIFEST: \(manifest)")
                    return
                }

                FontRegistry.register(family: family, fontName: fontName)
            }

        }

    }
}
