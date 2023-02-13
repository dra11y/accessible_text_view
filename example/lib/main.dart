import 'package:accessible_text_view/accessible_text_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:native_segments/native_segments.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() => runApp(const MaterialApp(home: TextViewExample()));

class TextViewExample extends StatefulWidget {
  const TextViewExample({super.key});

  @override
  State<TextViewExample> createState() => _TextViewExampleState();
}

class _TextViewExampleState extends State<TextViewExample> {
  bool isFlutterTextView = false;

  Widget get accessibleTextView => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AccessibleTextView(
          html: html,
          textStyle: normalStyle,
          linkStyle: linkStyle,
          brightness: Brightness.dark,
          useFlutterTextScale: true,
        ),
      );

  final String html1 = """
  This is short text.
""";

  final String html = """
    <p>This is an AccessibleTextView.</p>
    <p>This is a second paragraph with one <a href="https://google.com">Google</a> link.</p>
    <p>This is an example text with phone number 555-234-2345 with an e-mail link of test@example.com and a web link to <a href="https://google.com">Google</a>.
    On Android, TalkBack should indicate each link with a blip sound.
    On iOS, VoiceOver should navigate each paragraph separately, and provide a rotor and long-press popup menu (in VoiceOver only) for links.</p>
    <p>This component really should not be used for long text, because it is not designed for long text. For that, use a web view.</p>
  """;

  final TextStyle normalStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1.5,
  );

  final TextStyle linkStyle = const TextStyle(
    color: Colors.blueAccent,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
  );

  late final Widget flutterTextView = Text.rich(
    TextSpan(
      text: 'This is a Flutter Text.rich.',
      children: [
        const TextSpan(text: '\n\nThis is a second paragraph with one '),
        TextSpan(
          text: 'Google',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              await launchUrlString('https://google.com');
            },
        ),
        const TextSpan(text: ' link.'),
        TextSpan(
          text: '\n\nThis is an example text with phone number ',
          children: [
            TextSpan(
              text: '555-234-2345',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrlString('tel:555-234-2345');
                },
            ),
            const TextSpan(text: ' with an e-mail link of '),
            TextSpan(
              text: 'test@example.com',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrlString('mailto:test@example.com');
                },
            ),
            const TextSpan(text: ' and an external link to '),
            TextSpan(
              text: 'Google',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrlString('https://google.com');
                },
            ),
            const TextSpan(
                text:
                    '. On Android, TalkBack should indicate each link with a blip sound. '),
            const TextSpan(
                text:
                    'On iOS, VoiceOver should navigate each non-link and link chunk separately.'),
          ],
        ),
        const TextSpan(
            text:
                '\n\nThis component really should not be used for long text, because it is not designed for long text. For that, use a web view.'),
      ],
    ),
    style: normalStyle,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: const Text('Flutter TextView example'),
          ),
        ),
        backgroundColor: Colors.black38,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: [TargetPlatform.iOS, TargetPlatform.android]
                      .contains(defaultTargetPlatform)
                  ? NativeSegments(
                      segments: [
                        NativeSegment(title: 'AccessibleTextView'),
                        NativeSegment(title: 'Flutter Text.rich'),
                      ],
                      style: const NativeSegmentsStyle(
                        isDarkTheme: true,
                      ),
                      onValueChanged: (value) {
                        setState(() {
                          isFlutterTextView = value == 1;
                        });
                      },
                    )
                  : SegmentedButton(
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('AccessibleTextView'),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Flutter Text.rich'),
                        ),
                      ],
                      selected: {isFlutterTextView ? 1 : 0},
                      onSelectionChanged: (selectedSet) {
                        setState(() {
                          isFlutterTextView = selectedSet.contains(1);
                        });
                      },
                    ),
            ),
            Expanded(
              flex: 3,
              child: isFlutterTextView ? flutterTextView : accessibleTextView,
            ),
            Expanded(
                flex: 1,
                child: Container(
                    color: Colors.blue[100],
                    child: const Center(child: Text("Hello from Flutter!"))))
          ],
        ),
      ),
    );
  }
}
