import 'package:flutter/material.dart';

import '../domain/legal_content.dart';
import 'legal_screen.dart';

/// Route `/legal/privacy` — Informativa sulla Privacy / Privacy Policy.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalScreen(document: LegalContent.privacy);
}
