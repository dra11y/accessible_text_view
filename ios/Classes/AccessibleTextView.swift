//
//  TextView.swift
//  accessible_text_view
//
//  Created by Grushka, Tom on 1/20/23.
//

import Flutter
import UIKit

public extension UIFont {
    var weight: UIFont.Weight {
        if
            let traits = fontDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any],
            let weight = traits[.weight] as? CGFloat
        {
            return UIFont.Weight(weight)
        }
        return UIFont.Weight.medium
    }

    func withWeight(weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight.rawValue,
            ],
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

public extension CGRect {
    var center: CGPoint { .init(x: midX, y: midY) }
}

public enum TextViewAppearance: String, Codable {
    case light
    case dark
    case system

    @available(iOS 12.0, *)
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
}

public struct AccessibleTextViewOptions: Codable {
    let html: String?
    let textColor: [CGFloat]?
    let linkColor: [CGFloat]?
    let textWeight: Int?
    let linkWeight: Int?
    let backgroundColor: [CGFloat]?
    let fontFamily: String?
    let fontSize: CGFloat?
    let autoLinkify: Bool?
    let isSelectable: Bool?
    let minLines: Int?
    let maxLines: Int?
    let appearance: TextViewAppearance?
    let errorCode: String?
    let errorMessage: String?

    public init(
        html: String? = nil,
        textColor: [CGFloat]? = nil,
        linkColor: [CGFloat]? = nil,
        textWeight: Int? = nil,
        linkWeight: Int? = nil,
        backgroundColor: [CGFloat]? = nil,
        fontFamily: String? = nil,
        fontSize: CGFloat? = nil,
        autoLinkify: Bool? = nil,
        isSelectable: Bool? = nil,
        minLines: Int? = nil,
        maxLines: Int? = nil,
        appearance: TextViewAppearance? = nil,
        errorCode: String? = nil,
        errorMessage: String? = nil
    ) {
        self.html = html
        self.textColor = textColor
        self.linkColor = linkColor
        self.textWeight = textWeight
        self.linkWeight = linkWeight
        self.backgroundColor = backgroundColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.autoLinkify = autoLinkify
        self.isSelectable = isSelectable
        self.minLines = minLines
        self.maxLines = maxLines
        self.appearance = appearance
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }

    func uiTextWeight() -> CGFloat? {
        uiFontWeight(textWeight)
    }

    func uiLinkWeight() -> CGFloat? {
        uiFontWeight(linkWeight)
    }

    func uiFontWeight(_ weight: Int?) -> CGFloat? {
        guard let weight = weight else { return nil }
        let normalizedInt = CGFloat(weight - 400)
        // Flutter normal weight = 400, min = 100, max = 900
        // iOS min weight = -1.0, normal = 0.0, max = 1.0
        return normalizedInt < 0 ? normalizedInt / 300.0 : normalizedInt / 500.0
    }

    func uiTextColor() -> UIColor? {
        uiColor(textColor)
    }

    func uiLinkColor() -> UIColor? {
        uiColor(linkColor)
    }

    func uiBackgroundColor() -> UIColor? {
        uiColor(backgroundColor)
    }

    func uiFont() -> UIFont? {
        FontRegistry.resolve(family: fontFamily, size: fontSize)
    }

    private func uiColor(_ array: [CGFloat]?) -> UIColor? {
        guard
            let array = array,
            array.count == 4
        else { return nil }

        let red = array[1] / 255.0
        let green = array[2] / 255.0
        let blue = array[3] / 255.0
        let alpha = array[0] / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    func htmlToAttributedString() -> NSAttributedString? {
        guard
            let html = html,
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

public class MyTextView: UITextView, UITextViewDelegate, UIContextMenuInteractionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ -> UIMenu? in
            guard let self = self else { return nil }

            let actions = self.links.compactMap { link in
                UIAction(title: link.title) { _ in
                    UIApplication.shared.open(link.url)
                }
            }

            return UIMenu(title: actions.count == 1 ? "Link" : "Links", children: actions)
        }
    }
    
    public var didDetectVoiceControl: Bool = false

    private struct Link {
        let title: String
        let url: URL
    }

    private var links: [Link] {
        guard
            let paragraphs = self.accessibilityElements as? [UIAccessibilityElement],
            let links = paragraphs.flatMap({ $0.accessibilityElements ?? [] }) as? [UIAccessibilityElement]
        else { return [] }

        return links.compactMap { link -> Link? in
            guard
                link.responds(to: NSSelectorFromString("url")),
                let url = link.value(forKey: "url") as? URL,
                let title = link.accessibilityLabel
            else { return nil }

            return Link(title: title, url: url)
        }
    }

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        addATObservers()
        updateAccessibility()
    }

    private func updateAccessibility() {
        AXUITextViewParagraphElementSwizzler.swizzleIfNeeded()

        guard let linksMenuInteraction = linksMenuInteraction else { return }
        if UIAccessibility.isVoiceOverRunning {
            addInteraction(linksMenuInteraction)
        } else {
            removeInteraction(linksMenuInteraction)
        }
    }

    private lazy var linksMenuInteraction: UIInteraction? = {
        if #available(iOS 13.0, *) {
            return UIContextMenuInteraction(delegate: self)
        }
        return nil
    }()

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var channel: FlutterMethodChannel?

    public func textView(_: UITextView, shouldInteractWith _: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
        return true
    }

    private var atObservers: [NSObjectProtocol]?

    private var modifiedRotors: [UIAccessibilityCustomRotor]?

    override public var accessibilityHint: String? {
        get {
            links.count < 2
                ? super.accessibilityHint
                : "To access \(links.count) links, use the rotor, or double-tap and hold for context menu."
        }
        set { }
    }

    private func wrapSearchBlock(originalRotor: UIAccessibilityCustomRotor) -> UIAccessibilityCustomRotor {
        let originalSearchBlock = originalRotor.itemSearchBlock

        let newBlock: UIAccessibilityCustomRotor.Search = { [weak self] predicate -> UIAccessibilityCustomRotorItemResult in

            guard
                let self = self,
                let originalResult = originalSearchBlock(predicate)
            else { return UIAccessibilityCustomRotorItemResult() }

            let paragraphs = self.accessibilityElements as? [UIAccessibilityElement] ?? []

            let fallbackTarget = (
                paragraphs.first {
                    $0.accessibilityElements?.count ?? 0 > 0
                } ?? paragraphs.first ?? self)

            guard
                predicate.searchDirection == .previous,
                let focusedLink = predicate.currentItem.targetElement as? UIAccessibilityElement
            else { return originalResult }

            let isParagraph = focusedLink.accessibilityElements?.count ?? 0 > 0
            let newTarget: UIAccessibilityElement?

            if
                isParagraph,
                let index = paragraphs.firstIndex(where: { $0 == focusedLink }),
                index > 0
            {
                let previousParagraph = paragraphs[index - 1]
                let lastLinkOfPreviousParagraph = previousParagraph.accessibilityElements?.last as? UIAccessibilityElement
                newTarget = lastLinkOfPreviousParagraph ?? previousParagraph
            }
            else if
                let containingParagraph = focusedLink.accessibilityContainer as? UIAccessibilityElement,
                let firstLinkInParagraph = containingParagraph.accessibilityElements?.first as? UIAccessibilityElement,
                focusedLink == firstLinkInParagraph
            {
                newTarget = containingParagraph
            }
            else {
                newTarget = originalResult.targetElement as? UIAccessibilityElement
            }

            return UIAccessibilityCustomRotorItemResult(targetElement: newTarget ?? fallbackTarget, targetRange: nil)
        }

        return UIAccessibilityCustomRotor(systemType: .link, itemSearch: newBlock)
    }

    /// Override a bad default Apple experience in which one cannot navigate back to the
    /// paragraph text after entering the links rotor. Wrap the search block so that swiping
    /// up on the first link returns us to the text paragraph instead of getting stuck
    /// on the link. This still does not fix VoiceOver getting stuck when swiping
    /// left or right on a link.
    override public var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get {
            if let modifiedRotors = modifiedRotors {
                return modifiedRotors
            }
            guard let superRotors = super.accessibilityCustomRotors else { return nil }

            
            let rotors: [UIAccessibilityCustomRotor] = superRotors.map
            { (rotor: UIAccessibilityCustomRotor) in
                if rotor.systemRotorType != .link {
                    return rotor
                }
                return wrapSearchBlock(originalRotor: rotor)
            }

            modifiedRotors = rotors
            return rotors
        }
        set {}
    }

    override public var accessibilityElements: [Any]? {
        get {
            /// We need to flatten the elements for Switch Control and Voice Control,
            /// but NOT for VoiceOver (otherwise the plain text won't be focusable).
            /// So, we only flatten the elements when VoiceOver is not running.
            guard
                !UIAccessibility.isVoiceOverRunning,
                let elements = super.accessibilityElements as? [UIAccessibilityElement]
            else { return super.accessibilityElements }

            return elements.compactMap { element in
                element.accessibilityElements
            }
        }
        set {}
    }

    private func addATObservers() {
        guard atObservers == nil else { return }
        var observers = [NSObjectProtocol]()
        observers.append(
            NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in

                self?.updateAccessibility()
            })
        observers.append(
            NotificationCenter.default.addObserver(forName: UIAccessibility.switchControlStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in

                self?.updateAccessibility()
            })
        atObservers = observers
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        channel?.invokeMethod("wantsHeight", arguments: contentSize.height)
    }

    override public var isSelectable: Bool {
        get { super.isSelectable }
        set {
            super.isSelectable = newValue
            if newValue {
                removeGestureRecognizer(linkTapGestureRecognizer)
            } else {
                addGestureRecognizer(linkTapGestureRecognizer)
            }
        }
    }

    private lazy var linkTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if let range = characterRange(at: location) {
            let tapOffset = offset(from: beginningOfDocument, to: range.start)
            if let attribute = attributedText.attribute(.link, at: tapOffset, effectiveRange: nil) as? URL {
                UIApplication.shared.open(attribute)
            }
        }
    }
}

public class TextView: NSObject, FlutterPlatformView {
    public func view() -> UIView {
        textView
    }

    public init(
        withFrame frame: CGRect,
        viewId id: Int64,
        messenger: FlutterBinaryMessenger,
        arguments _: Any?
    ) {
        super.init()
        channel = FlutterMethodChannel(name: "com.dra11y.flutter/accessible_text_view_\(id)", binaryMessenger: messenger)
        channel.setMethodCallHandler(onMethodCall)
        textView = MyTextView(frame: frame)
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        // textView.dataDetectorTypes = .all
        textView.delegate = textView
        textView.channel = channel
    }

    private var textView: MyTextView!
    private var viewId: Int64 = 0
    private var channel: FlutterMethodChannel!

    private func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "setOptions":
            setOptions(call: call, result: result)
        default:
            break
        }
    }

    private func setOptions(call: FlutterMethodCall, result: FlutterResult) {
        guard let json = call.arguments as? String else {
            assertionFailure("No options provided.")
            return
        }

        let options = AccessibleTextViewOptions.from(json: json)

        if let attributedString = options.htmlToAttributedString() {
            textView.attributedText = attributedString
        }

        textView.adjustsFontForContentSizeCategory = true

        let textFont: UIFont
        if let font = options.uiFont() {
            textFont = UIFontMetrics.default.scaledFont(for: font)
        } else {
            textFont = textView.font ?? UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: UIFont.systemFontSize))
        }

        textView.font = textFont

        if let textColor = options.uiTextColor() {
            textView.textColor = textColor
        }

        var linkAttributes = [NSAttributedString.Key: Any]()
        if let linkColor = options.uiLinkColor() {
            linkAttributes[.foregroundColor] = linkColor
        }

        let textWeight: CGFloat
        if
            let traits = textFont.fontDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any],
            let weight = traits[.weight] as? CGFloat
        {
            textWeight = weight
            print("Got textWeight of \(weight)")
        } else {
            print("Taking default textWeight of 0.0")
            textWeight = 1.0 // normal
        }

        let linkWeight = options.uiLinkWeight() ?? textWeight

        let descriptor = textFont.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: linkWeight,
            ],
        ])
        let linkFont = UIFont(descriptor: descriptor, size: textFont.pointSize)
        linkAttributes[.font] = linkFont
        linkAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        textView.linkTextAttributes = linkAttributes

        /// Since Apple's iOS auto-detection does not work at all reliably:
        if
            options.autoLinkify == true,
            let detectionString = textView.attributedText?.mutableCopy() as? NSMutableAttributedString
        {
            let detectionResult = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.allTypes.rawValue).matches(
                in: detectionString.string,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSMakeRange(0, detectionString.string.count)
            )
            for result in detectionResult {
                let link: URL
                if let url = result.url {
                    link = url
                } else if let phone = result.phoneNumber {
                    link = URL(string: "tel:\(phone)")!
                } else {
                    return
                }
                detectionString.addAttributes(
                    linkAttributes
                        .merging(
                            [.link: link],
                            uniquingKeysWith: { _, new in new }
                        ),
                    range: result.range
                )
            }
            textView.attributedText = detectionString
        }

        if
            #available(iOS 13.0, *),
            let appearance = options.appearance
        {
            textView.overrideUserInterfaceStyle = appearance.userInterfaceStyle
            textView.window?.overrideUserInterfaceStyle = appearance.userInterfaceStyle
        }

        if let backgroundColor = options.uiBackgroundColor() {
            textView.backgroundColor = backgroundColor
        }

        if let isSelectable = options.isSelectable {
            textView.isSelectable = isSelectable
        }

        // https://github.com/henryleunghk/flutter-native-text-view/blob/master/ios/Classes/NativeTextView.m

        if let maxLines = options.maxLines {
            textView.textContainer.maximumNumberOfLines = maxLines
            textView.textContainer.lineBreakMode = .byTruncatingTail
        }

        result(nil)
    }
}
