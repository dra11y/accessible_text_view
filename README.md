# accessible_text_view

Renders a native platform text view to address accessibility with embedded links in Flutter Text and RichText widgets on Android.

Also works on iOS, with enhanced accessibility options.

## Accessibility Problems Solved

### Android

Flutter Text and Text.rich() or RichText widgets cannot currently handle links properly, until the Google Android team exposes the "link trait" in its `AccessibilityNodeInfo` class. Currently, only `URLSpan` spans in `SpannableString` instances on Android expose their links properly to TalkBack.

The expected behavior is for the entire text to be read, with a slight pause and distinctive "popping click" sound heard at each link in the text. The user can then tap with three fingers to get the TalkBack menu. In this context menu, there is a Links submenu containing the links. This behavior cannot currently be achieved by the Flutter framework because of the lack of public Android API available for this functionality.

__However, I also wish to advocate here for an option in Android to make these elements separately focusable for longer paragraphs and blocks of text.__ This would help TalkBack users to not have to listen to the entire text. The current Flutter Text widget implementation does support the links as separate focus nodes, but calls them out as buttons instead of links. If the Android team makes the "link trait" available in its public API so that the Flutter engine can use it without having to use a `TextView` with `Spannable` text, this end could be easily achieved by allowing `Semantics(link: true)` to work on Flutter `Text`, `RichText`, and `TextSpan`s.

### iOS

Fortunately, `UIKit` has an `UIAccessibilityTraits.link` attribute, and thus the Flutter links within `Text` and `TextSpan`s are correctly labelled. Additionally, Flutter gets it right by making them separate focus nodes by default. Unfortunately, iOS users may still get confused, because Apple has changed `UITextView` to behave more like Android `TextView`, in that links in a `UITextView` are no longer separate focus nodes. VoiceOver users must be more advanced and know to use the links rotor to access them. It seems that screen reader users are still left largely in the dark when it comes to embedded links in text, an all too common phenomenon in native apps, e.g. terms of service, support contact info, usage instructions, etc.

To brige the gap, I have enhanced the `UITextView` accessibility behavior by allowing the developer to choose one of the following beaviors appropriate to their app and the amount of text in the text view:


You can also use platform tests to use a Flutter implementation on iOS, and use this widget on Android, but I implemented native views on both platforms to facilitate easier implementation.

Besides, you can simply embed your links in HTML, and use data auto-detection (both Android and iOS) to auto-link phone numbers and e-mail addresses!

## Installation

`flutter pub add accessible_text_view`

### Dependencies

Other than Flutter, none!

## Usage Example

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: Semantics(
            header: true,
            child: const Text('Flutter TextView example'),
        ),
    ),
    backgroundColor: Colors.black38,
    body: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AccessibleTextView(
            html: """
            <p>This is an AccessibleTextView widget. Its behavior is more correct on Android and more flexible on iOS.</p>
            <p>This is a second paragraph.</p>
            <p>This is an example text with phone number 555-234-2345 with an e-mail link of test@example.com and an external link to <a href="https://google.com">Google</a>.
            On Android, TalkBack should indicate each link with a blip sound.
            On iOS, VoiceOver should provide a long-press links menu.</p>
            <p>This component really should not be used for long text, because it is not designed for long text. For that, use a web view.</p>
          """,
              textColor: Colors.white,
              linkWeight: FontWeight.bold,
              linkColor: Colors.blueAccent,
              appearance: AccessibleTextViewAppearance.dark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
```

## License

This plugin has a liberal MIT license to encourage accessibility in all app development. Please learn from it and use as you see fit in your own apps!

## Contributing

I would really appreciate learning who is using this plugin, and your feedback, and bugfix and feature requests. Please feel free to open an issue or pull request.

## Contributors

- Tom Grushka, principal developer
- Adam Campfield
