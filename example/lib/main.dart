import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:accessible_text_view/accessible_text_view.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() => runApp(const MaterialApp(home: TextViewExample()));

class TextViewExample extends StatefulWidget {
  const TextViewExample({super.key});

  @override
  State<TextViewExample> createState() => _TextViewExampleState();
}

class _TextViewExampleState extends State<TextViewExample> {
  bool isFlutterTextView = false;

  Widget get accessibleTextView => AccessibleTextView(
        html: """
    <p>This is an AccessibleTextView widget. Its behavior is more correct on Android and more flexible on iOS.</p>
    <p>This is a second paragraph with one <a href="https://google.com">Google</a> link.</p>
    <p>This is an example text with phone number 555-234-2345 with an e-mail link of test@example.com and a web link to <a href="https://google.com">Google</a>.
    On Android, TalkBack should indicate each link with a blip sound.
    On iOS, VoiceOver should navigate each non-link and link chunk separately.</p>
    <p>This component really should not be used for long text, because it is not designed for long text. For that, use a web view.</p>
""",
        // textColor: Theme.of(context).colorScheme.onSurface,
        textColor: Colors.white,
        linkWeight: FontWeight.bold,
        linkColor: Colors.blueAccent,
        appearance: AccessibleTextViewAppearance.dark,
        fontSize: 14,
      );

  final TextStyle flutterLinkStyle = const TextStyle(
    color: Colors.blueAccent,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
  );

  final TextStyle normalStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
  );

  late final Widget flutterTextView = Text.rich(
    TextSpan(
      text:
          'This is a Flutter Text.rich. Its accessibility behavior with links is correct on iOS, but not Android.',
      children: [
        const TextSpan(
            text:
                '\n\nOn Android, the links are separate nodes, but are called out as buttons instead of links. Android users expect the text to be continuous, with a TalkBack menu of links.'),
        TextSpan(
          text: '\n\nThis is an example text with phone number ',
          children: [
            TextSpan(
              text: '555-234-2345',
              style: flutterLinkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrlString('tel:555-234-2345');
                },
            ),
            const TextSpan(text: ' with an e-mail link of '),
            TextSpan(
              text: 'test@example.com',
              style: flutterLinkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrlString('mailto:test@example.com');
                },
            ),
            const TextSpan(text: ' and an external link to '),
            TextSpan(
              text: 'Google',
              style: flutterLinkStyle,
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
            TextButton(
              onPressed: () {
                setState(() {
                  isFlutterTextView = !isFlutterTextView;
                });
              },
              child: Text(
                  'Switch to ${isFlutterTextView ? 'Native AccessibleTextView' : 'Flutter Text.rich'}'),
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
