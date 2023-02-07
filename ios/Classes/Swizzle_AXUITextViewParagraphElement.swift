//
//  Swizzle_AXUITextViewParagraphElement.swift
//  accessible_text_view
//
//  Created by Tom Grushka on 1/30/23.
//

import ObjectiveC
import UIKit

private class Swizzled_AXUITextViewParagraphElement: UIAccessibilityElement {
    /// Don't automatically activate the first link on activation of the paragraph text.
    @objc dynamic func swizzled_accessibilityActivate() -> Bool {
        true
    }

    /// Don't give the whole paragraph text a .link attribute.
    @objc dynamic var swizzled_accessibilityTraits: UIAccessibilityTraits {
        get { .staticText }
        set {}
    }

    /// Use the hint of the parent UITextView.
    @objc dynamic var swizzled_accessibilityHint: String? {
        get { accessibilityContainer?.accessibilityHint }
        set {}
    }
}

enum AXUITextViewParagraphElementSwizzler {
    private static var isSwizzled = false // Make idempotent
    private static var retries = 3

    private static let swizzledClass: AnyClass = Swizzled_AXUITextViewParagraphElement.self

    private static let originalClassName = "_AXUITextViewParagraphElement"

    private static var originalClass: AnyClass?

    public static func swizzleIfNeeded() {
        /// `_AXUITextViewParagraphElement` does not exist if neither VoiceOver nor Switch Control
        /// is running, causing a crash. Therefore, we observe the state of these ATs
        /// and only swizzle when one is available.
        guard
            UIAccessibility.isVoiceOverRunning ||
            UIAccessibility.isSwitchControlRunning
        else { return }

        guard let klass = NSClassFromString(originalClassName)
        else {
            retries -= 1

            if retries < 0 {
                assertionFailure("Could not get \(originalClassName)!")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Self.swizzleIfNeeded()
            }
            return
        }

        originalClass = klass

        if Self.isSwizzled { return }
        Self.isSwizzled = true

        swizzle(
            originalSelector: #selector(UIAccessibilityElement.accessibilityTraits),
            swizzledSelector: #selector(getter: Swizzled_AXUITextViewParagraphElement.swizzled_accessibilityTraits)
        )

        swizzle(
            originalSelector: #selector(UIAccessibilityElement.accessibilityHint),
            swizzledSelector: #selector(getter: Swizzled_AXUITextViewParagraphElement.swizzled_accessibilityHint)
        )

        swizzle(
            originalSelector: #selector(UIAccessibilityElement.accessibilityActivate),
            swizzledSelector: #selector(Swizzled_AXUITextViewParagraphElement.swizzled_accessibilityActivate)
        )
    }

    private static func add(selector: Selector) {
        guard let originalClass = originalClass else {
            assertionFailure("No original class set!")
            return
        }

        guard
            let method = class_getInstanceMethod(swizzledClass, selector)
        else {
            assertionFailure("Could not get method to add: \(selector)")
            return
        }

        class_addMethod(originalClass, selector, method_getImplementation(method), method_getTypeEncoding(method))
    }

    private static func swizzle(originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalClass = originalClass else {
            assertionFailure("No original class set!")
            return
        }

        guard
            let originalMethod = class_getInstanceMethod(originalClass, originalSelector)
        else {
            assertionFailure("Could not get original method: \(originalSelector)")
            return
        }

        guard
            let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector)
        else {
            assertionFailure("Could not get swizzled method: \(swizzledSelector)")
            return
        }

        let didAdd = class_addMethod(originalClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))

        if didAdd {
            class_replaceMethod(originalClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
