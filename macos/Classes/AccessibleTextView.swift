//
//  TextView.swift
//  accessible_text_view
//
//  Created by Grushka, Tom on 12-Feb-23.
//

import FlutterMacOS
import native_flutter_fonts
import Cocoa

public extension NSFont {
    var traits: [NSFontDescriptor.TraitKey: Any]? {
        fontDescriptor.fontAttributes[.traits] as? [NSFontDescriptor.TraitKey: Any]
    }

    var isItalic: Bool {
        if
            let traits = traits,
            let slant = traits[.slant] as? CGFloat
        {
            return slant != 0.0
        }

        return false
    }

    var weight: NSFont.Weight {
        if
            let traits = traits,
            let weight = traits[.weight] as? CGFloat
        {
            return NSFont.Weight(weight)
        }
        return NSFont.Weight.medium
    }

    func withWeight(weight: NSFont.Weight) -> NSFont {
        let descriptor = fontDescriptor.addingAttributes([
            NSFontDescriptor.AttributeName.traits: [
                NSFontDescriptor.TraitKey.weight: weight.rawValue,
            ],
        ])
        return NSFont(descriptor: descriptor, size: pointSize) ?? NSFont.systemFont(ofSize: pointSize)
    }
}

public extension CGRect {
    var center: CGPoint { .init(x: midX, y: midY) }
}

public enum Brightness: String, Codable {
    case light
    case dark

    public var userInterfaceStyle: NSAppearance {
        switch self {
        case .light:
            return .init(named: .aqua)!
        case .dark:
            return .init(named: .darkAqua)!
        }
    }
}

public typealias APIColor = [CGFloat]

extension APIColor {
    public var uiColor: NSColor? {
        guard count == 4
        else { return nil }

        let red = self[1] / 255.0
        let green = self[2] / 255.0
        let blue = self[3] / 255.0
        let alpha = self[0] / 255.0

        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public class TextStyle: Codable {
    let color: APIColor?
    let backgroundColor: APIColor?
    let fontFamily: String?
    let fontSize: CGFloat?
    let fontWeight: Int?
    let fontStyle: String?
    let letterSpacing: CGFloat?
    let wordSpacing: CGFloat?
    let height: CGFloat?
    let decoration: String?
    let decorationColor: APIColor?
    let decorationStyle: String?
    let decorationThickness: CGFloat?
    let overflow: String?

    public init(
        color: APIColor?,
        backgroundColor: APIColor?,
        fontFamily: String?,
        fontSize: CGFloat?,
        fontWeight: Int?,
        fontStyle: String?,
        letterSpacing: CGFloat?,
        wordSpacing: CGFloat?,
        height: CGFloat?,
        decoration: String?,
        decorationColor: APIColor?,
        decorationStyle: String?,
        decorationThickness: CGFloat?,
        overflow: String?
    ) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.letterSpacing = letterSpacing
        self.wordSpacing = wordSpacing
        self.height = height
        self.decoration = decoration
        self.decorationColor = decorationColor
        self.decorationStyle = decorationStyle
        self.decorationThickness = decorationThickness
        self.overflow = overflow
    }

    public func resolveFont(useFlutterScale: Bool?, flutterScaleFactor: CGFloat?) -> NSFont {
        let size = fontSize ?? NSFont.systemFontSize
        let font = FlutterFontRegistry.resolveOrSystemDefault(
            family: fontFamily,
            size: size,
            weight: fontWeight)
        let scaledSize = size * (flutterScaleFactor ?? 1.0)
        return NSFont(descriptor: font.fontDescriptor, size: scaledSize) ?? NSFont.systemFont(ofSize: scaledSize)
    }

    public var uiWeight: CGFloat {
        FlutterFontRegistry.appleWeightFromFlutterWeight(fontWeight ?? 400)
    }

}

public struct AccessibleTextViewOptions: Codable {
    let html: String?
    let textStyle: TextStyle?
    let linkStyle: TextStyle?
    let useFlutterTextScale: Bool?
    let flutterTextScaleFactor: CGFloat?
    let backgroundColor: APIColor?
    let autoLinkify: Bool?
    let isSelectable: Bool?
    let minLines: Int?
    let maxLines: Int?
    let brightness: Brightness?
    let errorCode: String?
    let errorMessage: String?

    public func copyWith(_ newOptions: AccessibleTextViewOptions) -> AccessibleTextViewOptions
    {
        AccessibleTextViewOptions(
            html: newOptions.html ?? self.html,
            textStyle: newOptions.textStyle ?? self.textStyle,
            linkStyle: newOptions.linkStyle ?? self.linkStyle,
            useFlutterTextScale: newOptions.useFlutterTextScale ?? self.useFlutterTextScale,
            flutterTextScaleFactor: newOptions.flutterTextScaleFactor ?? self.flutterTextScaleFactor,
            backgroundColor: newOptions.backgroundColor ?? self.backgroundColor,
            autoLinkify: newOptions.autoLinkify ?? self.autoLinkify,
            isSelectable: newOptions.isSelectable ?? self.isSelectable,
            minLines: newOptions.minLines ?? self.minLines,
            maxLines: newOptions.maxLines ?? self.maxLines,
            brightness: newOptions.brightness ?? self.brightness,
            errorCode: newOptions.errorCode ?? self.errorCode,
            errorMessage: newOptions.errorMessage ?? self.errorMessage)
    }

    public init(
        html: String? = nil,
        textStyle: TextStyle? = nil,
        linkStyle: TextStyle? = nil,
        useFlutterTextScale: Bool? = nil,
        flutterTextScaleFactor: CGFloat? = nil,
        backgroundColor: APIColor? = nil,
        autoLinkify: Bool? = nil,
        isSelectable: Bool? = nil,
        minLines: Int? = nil,
        maxLines: Int? = nil,
        brightness: Brightness? = nil,
        errorCode: String? = nil,
        errorMessage: String? = nil)
    {
        self.html = html
        self.textStyle = textStyle
        self.linkStyle = linkStyle
        self.useFlutterTextScale = useFlutterTextScale
        self.flutterTextScaleFactor = flutterTextScaleFactor
        self.backgroundColor = backgroundColor
        self.autoLinkify = autoLinkify
        self.isSelectable = isSelectable
        self.minLines = minLines
        self.maxLines = maxLines
        self.brightness = brightness
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }

    func htmlToAttributedString() -> NSAttributedString? {
        guard
            let html = html,
            !html.isEmpty,
            let data = html.data(using: .utf8)
        else { return nil }

        return try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
    }

    static func from(json: String) -> AccessibleTextViewOptions {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let options = try decoder.decode(AccessibleTextViewOptions.self, from: data)
            return options
        } catch {
            return AccessibleTextViewOptions(
                errorCode: "JSONError",
                errorMessage: error.localizedDescription
            )
        }
    }
}

public class TextView: NSTextView, NSTextViewDelegate {
    public func setup(
        viewId: Int64,
        messenger: FlutterBinaryMessenger
    ) {
        print("setup NSTextView with viewId = \(viewId)")
        self.viewId = viewId
        let channel = FlutterMethodChannel(name: "com.dra11y.flutter/accessible_text_view/\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler(onMethodCall)
        self.channel = channel

        isEditable = false
        isAutomaticDataDetectionEnabled = true
        delegate = self
    }

    override public func layout() {
        super.layout()
        let textRange = NSRange(location: 0, length: string.utf16.count)
        let rect = layoutManager!.boundingRect(forGlyphRange: textRange, in: textContainer!)
        print("wantsHeight = \(rect.size.height)")
        channel?.invokeMethod("wantsHeight", arguments: rect.size.height)
    }

    private var viewId: Int64 = 0
    private var channel: FlutterMethodChannel?
    private var options = AccessibleTextViewOptions()

    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setOptions":
            setOptions(call: call, result: result)
        default:
            break
        }
    }

    private func flutterError(_ result: FlutterResult?, _ message: String?) {
        guard let result = result else { return }
        result(FlutterError(code: "AccessibleTextViewOptions", message: message, details: nil))
    }

    private func update(_ result: FlutterResult? = nil) {
        guard
            let htmlAttributedString = options.htmlToAttributedString()
        else {
            flutterError(result, "html cannot be blank.")
            return
        }

        var additionalTextAttributes = [NSAttributedString.Key: Any]()

        let fontSize = options.textStyle?.fontSize ?? NSFont.systemFontSize

        let fallbackFont = NSFont.systemFont(ofSize: fontSize)

        let textFont = options.textStyle?.resolveFont(
            useFlutterScale: options.useFlutterTextScale,
            flutterScaleFactor: options.flutterTextScaleFactor)
            ?? fallbackFont
        additionalTextAttributes[.font] = textFont

        let linkFont = options.linkStyle?.resolveFont(
            useFlutterScale: options.useFlutterTextScale,
            flutterScaleFactor: options.flutterTextScaleFactor)
            ?? textFont

        if let height = options.textStyle?.height {
            var range = NSRange(location: 0, length: htmlAttributedString.length)
            if
                let paragraphStyle = (
                    (htmlAttributedString.attribute(.paragraphStyle, at: 0, effectiveRange: &range) as? NSParagraphStyle)
                    ?? NSParagraphStyle()
                ).mutableCopy() as? NSMutableParagraphStyle
            {
                paragraphStyle.lineSpacing = fontSize * (height - 1.0)
                additionalTextAttributes[.paragraphStyle] = paragraphStyle
            }
        }

        let mutableString = NSMutableAttributedString(attributedString: htmlAttributedString)
        mutableString.addAttributes(additionalTextAttributes, range: NSRange(location: 0, length: mutableString.length))
        textStorage?.setAttributedString(
            NSAttributedString(attributedString: mutableString))

        if let textColor = options.textStyle?.color?.uiColor {
            self.textColor = textColor
        }

        var linkAttributes = [NSAttributedString.Key: Any]()
        if let linkColor = options.linkStyle?.color?.uiColor {
            linkAttributes[.foregroundColor] = linkColor
        }

        let textWeight: CGFloat
        if
            let traits = textFont.fontDescriptor.fontAttributes[.traits] as? [NSFontDescriptor.TraitKey: Any],
            let weight = traits[.weight] as? CGFloat
        {
            textWeight = weight
        } else {
            textWeight = 1.0 // normal
        }

        let linkWeight = options.linkStyle?.uiWeight ?? textWeight

        let descriptor = linkFont.fontDescriptor.addingAttributes([
            NSFontDescriptor.AttributeName.traits: [
                NSFontDescriptor.TraitKey.weight: linkWeight,
            ],
        ])
        let updatedLinkFont = NSFont(descriptor: descriptor, size: textFont.pointSize)
        linkAttributes[.font] = updatedLinkFont
        linkAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        linkTextAttributes = linkAttributes

        /// Since Apple's iOS auto-detection does not work at all reliably:
//        if
//            options.autoLinkify == true,
//            let detectionString = textView.attributedString().mutableCopy() as? NSMutableAttributedString
//        {
//            let detectionResult = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.allTypes.rawValue).matches(
//                in: detectionString.string,
//                options: NSRegularExpression.MatchingOptions(rawValue: 0),
//                range: NSMakeRange(0, detectionString.string.count)
//            )
//            for result in detectionResult {
//                let link: URL
//                if let url = result.url {
//                    link = url
//                } else if let phone = result.phoneNumber {
//                    link = URL(string: "tel:\(phone)")!
//                } else {
//                    return
//                }
//                detectionString.addAttributes(
//                    linkAttributes
//                        .merging(
//                            [.link: link],
//                            uniquingKeysWith: { _, new in new }
//                        ),
//                    range: result.range
//                )
//            }
//            textView.textStorage?.setAttributedString(detectionString)
//        }

        if let appearance = options.brightness
        {
            self.appearance = appearance.userInterfaceStyle
//            window?.appearance = appearance.userInterfaceStyle
        }

        if let backgroundColor = options.backgroundColor?.uiColor {
            self.backgroundColor = backgroundColor
        }

        if let isSelectable = options.isSelectable {
            self.isSelectable = isSelectable
        }

        // https://github.com/henryleunghk/flutter-native-text-view/blob/master/ios/Classes/NativeTextView.m

        if let maxLines = options.maxLines {
            self.textContainer?.maximumNumberOfLines = maxLines
            self.textContainer?.lineBreakMode = .byTruncatingTail
        }

        result?(nil)
    }

    private func setOptions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let json = call.arguments as? String else {
            assertionFailure("No options provided.")
            return
        }

        options = options.copyWith(AccessibleTextViewOptions.from(json: json))

        update(result)
    }
}
