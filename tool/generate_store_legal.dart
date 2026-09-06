// Renders the ENGLISH Terms & Conditions and Privacy Policy as two separate,
// standalone pages — the two URLs Google Play and the App Store ask for.
//
// The text is not retyped here: it is read from the same source the in-app
// legal screens render (lib/features/legal/domain/legal_content.dart), so the
// hosted page and the app can never disagree — which is exactly what a store
// reviewer checks.
//
//   dart run tool/generate_store_legal.dart [outputDir]
//
// With the owner's details, which is how the final pages should be made:
//
//   dart run \
//     --define=LEGAL_ENTITY_NAME="Acme S.r.l." \
//     --define=LEGAL_SUPPORT_EMAIL="support@example.com" \
//     --define=LEGAL_PRIVACY_EMAIL="privacy@example.com" \
//     --define=LEGAL_COUNTRY="Italia" \
//     tool/generate_store_legal.dart out/
//
// Without them the pages still render, but every gap is marked with a loud
// TO FILL IN box — a policy that says "owner to be designated" is a rejection
// waiting to happen, so it should be impossible to publish one by accident.
import 'dart:io';

import 'package:gioco_del_101/core/legal/legal_config.dart';
import 'package:gioco_del_101/features/legal/domain/legal_content.dart';

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Turns `text in backticks` into <code>, after escaping. Line breaks are
/// left alone: the stylesheet renders paragraphs with `white-space:pre-line`,
/// so the bulleted lists in the source text keep their shape.
String _inline(String s) => _escape(s).replaceAllMapped(
  RegExp(r'`([^`]+)`'),
  (m) => '<code>${m[1]}</code>',
);

const _style = '''
:root{color-scheme:light}
body{margin:0 auto;max-width:780px;padding:40px 22px 72px;
  font-family:Georgia,"Times New Roman",serif;line-height:1.65;
  color:#241d16;background:#faf6ee}
header{border-bottom:2px solid #d9a441;padding-bottom:.6em;margin-bottom:1.2em}
h1{font-size:1.75em;margin:0 0 .2em}
.app{font-size:.95em;color:#6d6152;margin:0}
.updated{color:#7a6f5f;font-size:.9em;margin:.4em 0 0}
h2{font-size:1.12em;margin-top:2em;margin-bottom:.4em}
p{white-space:pre-line;margin:.4em 0}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.9em;
  background:#f0e8d8;padding:.05em .35em;border-radius:3px}
.todo{background:#fff3f0;border:2px solid #c0392b;border-radius:6px;
  padding:14px 18px;margin:1.4em 0;font-family:system-ui,sans-serif;
  font-size:.95em;color:#7b241c}
.todo b{display:block;margin-bottom:.3em}
footer{margin-top:3.5em;border-top:1px solid #d9cbb2;padding-top:1em;
  font-size:.85em;color:#7a6f5f}
''';

String _page(LegalDocument doc, List<String> missing) {
  final b = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..writeln('<title>${_escape(doc.title)} — Gioco del 101</title>')
    ..writeln('<style>$_style</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<header>')
    ..writeln('<h1>${_escape(doc.title)}</h1>')
    ..writeln(
      '<p class="app">Gioco del 101 — Android '
      '<code>it.giocodel101.gioco_del_101</code></p>',
    )
    ..writeln(
      '<p class="updated">Last updated: ${_escape(LegalConfig.lastUpdated)}</p>',
    )
    ..writeln('</header>');

  if (missing.isNotEmpty) {
    b
      ..writeln('<div class="todo">')
      ..writeln('<b>TO FILL IN BEFORE PUBLISHING THIS PAGE</b>')
      ..writeln(
        'This document is complete except for the details only the owner '
        'has. Google Play rejects a policy that does not name a real '
        'publisher and a real contact address. Missing: '
        '${_escape(missing.join(', '))}.',
      )
      ..writeln('</div>');
  }

  for (final s in doc.sections) {
    b
      ..writeln('<h2>${_escape(s.title)}</h2>')
      ..writeln('<p>${_inline(s.body)}</p>');
  }

  b
    ..writeln('<footer>')
    ..writeln(
      'This page is generated from the text shown inside the app, so the '
      'two are always identical.',
    )
    ..writeln('</footer>')
    ..writeln('</body>')
    ..writeln('</html>');
  return b.toString();
}

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'store/legal' : args.first)
    ..createSync(recursive: true);

  final missing = <String>[
    if (!LegalConfig.hasEntityName) 'the publisher’s legal name',
    if (!LegalConfig.hasSupportEmail) 'the support email',
    if (!LegalConfig.hasPrivacyEmail) 'the privacy email',
    if (!LegalConfig.hasCountry) 'the governing-law country',
  ];

  for (final (name, doc) in [
    ('terms-and-conditions.html', LegalContent.terms('en')),
    ('privacy-policy.html', LegalContent.privacy('en')),
  ]) {
    File('${dir.path}/$name').writeAsStringSync(_page(doc, missing));
    stdout.writeln('wrote ${dir.path}/$name');
  }

  if (missing.isNotEmpty) {
    stdout.writeln('\nSTILL MISSING: ${missing.join(', ')}');
    stdout.writeln('Re-run with --define=LEGAL_… to produce the final pages.');
  }
}
