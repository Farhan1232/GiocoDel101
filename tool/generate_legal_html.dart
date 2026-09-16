// Renders the in-app legal documents (lib/features/legal/domain/
// legal_content.dart) into the hostable static pages the client uploads to
// their website — the URLs Google Play Console and App Store Connect ask
// for. One source of truth: the HTML is generated FROM the app's text, so
// the hosted policy can never drift from the one inside the app.
//
//   dart run tool/generate_legal_html.dart
//
// Writes docs/legal/terms-and-conditions.html and
// docs/legal/privacy-policy.html, each with the Italian text first and the
// English text below it.
import 'dart:io';

import 'package:gioco_del_101/features/legal/domain/legal_content.dart';
import 'package:gioco_del_101/core/legal/legal_config.dart';

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _document({
  required LegalDocument it,
  required LegalDocument en,
  required String pageTitle,
}) {
  final buffer = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="it">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..writeln('<title>${_escape(pageTitle)} — Gioco del 101</title>')
    ..writeln('<style>')
    ..writeln(
      'body{margin:0 auto;max-width:760px;padding:32px 20px;'
      'font-family:Georgia,"Times New Roman",serif;line-height:1.6;'
      'color:#241d16;background:#faf6ee}'
      'h1{font-size:1.7em;border-bottom:2px solid #d9a441;'
      'padding-bottom:.35em}'
      'h2{font-size:1.15em;margin-top:1.6em}'
      'p{white-space:pre-line}'
      '.updated{color:#7a6f5f;font-size:.9em}'
      '.lang{margin-top:3em;border-top:1px solid #d9cbb2;padding-top:1.5em}',
    )
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>');

  for (final (doc, updatedLabel) in [
    (it, 'Ultimo aggiornamento'),
    (en, 'Last updated'),
  ]) {
    buffer
      ..writeln('<section class="lang" lang="${doc == en ? 'en' : 'it'}">')
      ..writeln('<h1>${_escape(doc.title)} — Gioco del 101</h1>')
      ..writeln(
        '<p class="updated">$updatedLabel: '
        '${_escape(LegalConfig.lastUpdated)}</p>',
      );
    for (final section in doc.sections) {
      buffer
        ..writeln('<h2>${_escape(section.title)}</h2>')
        ..writeln('<p>${_escape(section.body)}</p>');
    }
    buffer.writeln('</section>');
  }

  buffer
    ..writeln('</body>')
    ..writeln('</html>');
  return buffer.toString();
}

void main() {
  Directory('docs/legal').createSync(recursive: true);
  File('docs/legal/terms-and-conditions.html').writeAsStringSync(
    _document(
      it: LegalContent.terms('it'),
      en: LegalContent.terms('en'),
      pageTitle: 'Termini e Condizioni / Terms & Conditions',
    ),
  );
  File('docs/legal/privacy-policy.html').writeAsStringSync(
    _document(
      it: LegalContent.privacy('it'),
      en: LegalContent.privacy('en'),
      pageTitle: 'Informativa sulla Privacy / Privacy Policy',
    ),
  );
  stdout.writeln('wrote docs/legal/terms-and-conditions.html');
  stdout.writeln('wrote docs/legal/privacy-policy.html');
}
