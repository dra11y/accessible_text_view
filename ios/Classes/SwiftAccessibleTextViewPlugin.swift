import Flutter
import UIKit

public class SwiftAccessibleTextViewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = AccessibleTextViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.dra11y.flutter/accessible_text_view")
    }
}
