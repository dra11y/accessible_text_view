import Cocoa
import FlutterMacOS

public class AccessibleTextViewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = AccessibleTextViewFactory(messenger: registrar.messenger)
        registrar.register(factory, withId: "com.dra11y.flutter/accessible_text_view")
    }
}
