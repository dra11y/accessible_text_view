import 'package:flutter/material.dart';
import 'package:accessible_text_view/accessible_text_view.dart';

void main() => runApp(const MaterialApp(home: TextViewExample()));

class TextViewExample extends StatelessWidget {
  const TextViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Semantics(
              header: true,
              button: true,
              child: const Text('Flutter TextView example'),
            ),
          ),
          backgroundColor: Colors.black38,
          body: Column(children: [
            const Expanded(
              flex: 3,
              child: NativeTextView(
                html: """
    <p>This is the first paragraph.</p>
    <p>This is a second paragraph.</p>
    <p>This is an example text with phone number 555-234-2345 with an e-mail link of tom@dra11y.com and an external link to <a href="https://google.com">Google</a>.
    On Android, TalkBack should indicate each link with a blip sound.
    On iOS, VoiceOver should navigate each non-link and link chunk separately.
    
    <p>This component really should not be used for long text, because it is not designed for long text. For that, use a web view.</p>
                    """,
                // textColor: Theme.of(context).colorScheme.onSurface,
                textColor: Colors.white,
                linkWeight: FontWeight.bold,
                linkColor: Colors.blueAccent,
                appearance: NativeTextViewAppearance.dark,
                fontSize: 14,
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                    color: Colors.blue[100],
                    child: const Center(child: Text("Hello from Flutter!"))))
          ])),
    );
  }
}
