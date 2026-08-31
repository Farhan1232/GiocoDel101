import 'package:flutter/material.dart';

import '../domain/legal_content.dart';
import 'legal_screen.dart';

/// Route `/legal/terms` — Termini e Condizioni / Terms & Conditions.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalScreen(document: LegalContent.terms);
}
