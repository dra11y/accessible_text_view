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

public enum AccessibilityBehavior: String, Codable {
    case platformDefault
    case longPressMenu
    case linksAsFocusNodes
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
    let accessibilityBehavior: AccessibilityBehavior?

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
        errorMessage: String? = nil,
        accessibilityBehavior: AccessibilityBehavior? = nil
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
        self.accessibilityBehavior = accessibilityBehavior
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

public class URLAccessibilityElement: UIAccessibilityElement {
    public var url: NSURL?

    override public func accessibilityElementDidBecomeFocused() {
        (accessibilityContainer as? MyTextView)?.elementFocused(self)
    }

    override public func accessibilityActivate() -> Bool {
        guard let url = url else { return false }
        UIApplication.shared.open(url as URL)
        return true
    }

    // Do not focus with Switch Control if we don't have a URL.
    override public var accessibilityRespondsToUserInteraction: Bool {
        get { url != nil }
        set {}
    }

    override public var accessibilityTraits: UIAccessibilityTraits {
        get { url == nil ? super.accessibilityTraits : super.accessibilityTraits.union(.link) }
        set { super.accessibilityTraits = newValue }
    }
}

public class MyTextView: UITextView, UITextViewDelegate, UIContextMenuInteractionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ -> UIMenu? in
            guard let self = self else { return nil }

            let actions = self.popupLinks.map { link in
                UIAction(title: link.substring.string) { _ in
                    UIApplication.shared.open(link.url)
                }
            }

            return UIMenu(title: "Links", children: actions)
        }
    }

    override public func accessibilityActivate() -> Bool {
        UIAccessibility.post(notification: .layoutChanged, argument: self)
        return false
    }

    public var channel: FlutterMethodChannel?

    public func textView(_: UITextView, shouldInteractWith _: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
        return true
    }

    public var accessibilityBehavior: AccessibilityBehavior = .platformDefault

    private var focusNodeElements = [URLAccessibilityElement]()
    private var voiceOverObserver: NSObjectProtocol?
    private var updateAccessibilityTask: DispatchWorkItem?

    func elementFocused(_: URLAccessibilityElement) {
//        guard
//            let rectInScreen = element.accessibilityPath?.bounds,
//            let rectInWindow = window?.convert(rectInScreen, from: nil)
//        else { return }
//        let rectInView = convert(rectInWindow, from: nil)
    }

    public func scrollViewDidScroll(_: UIScrollView) {
        updateAccessibility()
    }

    private lazy var linksRotor: UIAccessibilityCustomRotor = .init(systemType: .link, itemSearch: { predicate in
        let isForward = predicate.searchDirection == .next

        guard
            self.focusNodeElements.count > 1,
            let current = predicate.currentItem.targetElement as? URLAccessibilityElement,
            let currentIndex = self.focusNodeElements.firstIndex(of: current)
        else {
            return nil
        }

        let searchArray: [URLAccessibilityElement] = isForward ? Array(self.focusNodeElements[(currentIndex + 1) ..< self.focusNodeElements.count]) : Array(self.focusNodeElements[0 ..< currentIndex].reversed())

        if let link = searchArray.first(where: { $0.url != nil }) {
            return UIAccessibilityCustomRotorItemResult(targetElement: link, targetRange: nil)
        }

        return nil
    })

    override public var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get {
            switch accessibilityBehavior {
            case .platformDefault:
                return super.accessibilityCustomRotors
            case .longPressMenu:
                return super.accessibilityCustomRotors
            case .linksAsFocusNodes:
                return [linksRotor]
            }
        }
        set {}
    }

    override public var isAccessibilityElement: Bool {
        get {
            switch accessibilityBehavior {
            case .platformDefault:
                return super.isAccessibilityElement
            case .longPressMenu:
                return !UIAccessibility.isSwitchControlRunning
            case .linksAsFocusNodes:
                return false
            }
        }
        set {}
    }

    override public var accessibilityElements: [Any]? {
        get {
            switch accessibilityBehavior {
            case .platformDefault:
                return super.accessibilityElements
            case .longPressMenu:
                return UIAccessibility.isSwitchControlRunning ? focusNodeElements : super.accessibilityElements
            case .linksAsFocusNodes:
                return focusNodeElements
            }
        }
        set {}
    }

    override public var attributedText: NSAttributedString! {
        didSet {
            updateAccessibility()
            addVoiceOverObserverIfNeeded()
        }
    }

    override public var accessibilityHint: String? {
        get {
            if let hint = super.accessibilityHint {
                return hint
            }
            if
                accessibilityBehavior == .longPressMenu
                && !popupLinks.isEmpty
            {
                return "To access links, use the rotor, or double-tap and hold for context menu."
            }
            return nil
        }
        set { super.accessibilityHint = newValue }
    }

    private func addVoiceOverObserverIfNeeded() {
        guard voiceOverObserver == nil else { return }
        voiceOverObserver = NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateAccessibility(delay: 0.5)
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        channel?.invokeMethod("wantsHeight", arguments: contentSize.height)
        updateAccessibility(delay: 0.5)
    }

    private typealias Link = (substring: NSAttributedString, url: URL)

    private var popupLinks = [Link]()

    public func updateAccessibility(delay: TimeInterval = 0.1) {
        if accessibilityBehavior == .platformDefault { return }

        updateAccessibilityTask?.cancel()

        let task = DispatchWorkItem { [weak self] in
            if self?.updateAccessibilityTask?.isCancelled == true {
                return
            }
            self?.updateAccessibilityNow()
        }

        updateAccessibilityTask = task
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: task)
    }

    private func updateAccessibilityNow() {
        updateAccessibilityTask?.cancel()

        guard let attrText = attributedText else { return }
        switch accessibilityBehavior {
        case .platformDefault:
            return
        case .linksAsFocusNodes:
            updateLinksAsFocusNodes(attrText: attrText)
        case .longPressMenu:
            updateLinksAsFocusNodes(attrText: attrText, linksOnly: true)
            updateLinksForContextMenu(attrText: attrText)
        }
    }

    private var menuInteractionAdded = false

    private func updateLinksForContextMenu(attrText: NSAttributedString) {
        popupLinks.removeAll()
        attrText.enumerateAttribute(
            .link,
            in: NSRange(0 ..< attrText.length)
        ) {
            value, range, _ in
            guard let url = value as? URL else { return }
            let text = attrText.attributedSubstring(from: range)
            let link = Link(substring: text, url: url)
            popupLinks.append(link)
        }
        if #available(iOS 13.0, *) {
            if !menuInteractionAdded {
                menuInteractionAdded = true
                let interaction = UIContextMenuInteraction(delegate: self)
                self.addInteraction(interaction)
            }
        }
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

    private func updateLinksAsFocusNodes(attrText: NSAttributedString, linksOnly: Bool = false) {
        var elements = [URLAccessibilityElement]()
        let focusedLabel = (UIAccessibility.focusedElement(using: nil) as? URLAccessibilityElement)?.accessibilityAttributedLabel
        var focusedElement: URLAccessibilityElement?
        attrText.enumerateAttribute(
            .link,
            in: NSRange(0 ..< attrText.length)
        ) {
            urlValue, range, _ in
            guard
                !linksOnly || urlValue != nil,
                let start = position(from: beginningOfDocument, offset: range.lowerBound),
                let end = position(from: beginningOfDocument, offset: range.upperBound),
                let textRange = textRange(from: start, to: end)
            else { return }
            let rects = selectionRects(for: textRange).compactMap { rect in
                rect.rect.isEmpty ? nil : rect.rect
            }
            guard
                !rects.isEmpty,
                let first = rects.first
            else { return }
            let path = UIBezierPath()
            path.move(to: CGPoint(x: first.minX, y: first.minY))
            for rect in rects {
                let topRight = CGPoint(x: rect.maxX, y: rect.minY)
                let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
                if topRight != path.currentPoint {
                    path.addLine(to: topRight)
                }
                if bottomRight != path.currentPoint {
                    path.addLine(to: bottomRight)
                }
            }
            for rect in rects.reversed() {
                let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
                let topLeft = CGPoint(x: rect.minX, y: rect.minY)
                if bottomLeft != path.currentPoint {
                    path.addLine(to: bottomLeft)
                }
                if topLeft != path.currentPoint {
                    path.addLine(to: topLeft)
                }
            }
            let text = attrText.attributedSubstring(from: range)
            let url = urlValue as? NSURL
            let element = URLAccessibilityElement(accessibilityContainer: self)
            let screenPath = UIAccessibility.convertToScreenCoordinates(path, in: self)
            element.accessibilityPath = screenPath
            element.accessibilityFrameInContainerSpace = path.bounds
            // This must be set or activation will not work.
            element.accessibilityActivationPoint = screenPath.bounds.center
            element.accessibilityAttributedLabel = text
            if let url = url {
                element.url = url
                let hint: String?
                switch url.scheme {
                case "mailto":
                    hint = "Compose e-mail."
                case "tel":
                    hint = "Dial phone number."
                case "http", "https":
                    if let host = url.host {
                        hint = "Open web site at \(host)"
                    } else {
                        hint = "Open web site."
                    }
                default:
                    hint = nil
                }
                element.accessibilityHint = hint
            }
            elements.append(element)
            if text == focusedLabel {
                focusedElement = element
            }
        }
        focusNodeElements = elements
        if focusedLabel != nil && focusedElement == nil {
            focusedElement = elements.first
        }
        if let focusedElement = focusedElement {
            UIAccessibility.post(notification: .layoutChanged, argument: focusedElement)
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

        if let accessibilityBehavior = options.accessibilityBehavior {
            textView.accessibilityBehavior = accessibilityBehavior
        }

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

        textView.updateAccessibility(delay: 1.0)

        result(nil)
    }
}
