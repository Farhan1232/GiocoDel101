import 'package:flutter/material.dart';

/// §46 — the emblem carved into an avatar medallion. Original heraldic
/// shapes, drawn by [MedallionPainter]; no stock photography anywhere.
enum MedallionMotif { sun, wave, arch, lyre, olive, mask, anchor, star }

class AvatarDef {
  const AvatarDef({
    required this.id,
    required this.name,
    required this.motif,
    required this.base,
    required this.emblem,
    required this.rim,
  });

  final String id;
  final String name;
  final MedallionMotif motif;
  final Color base;
  final Color emblem;
  final Color rim;
}

class Avatars {
  const Avatars._();

  static const List<AvatarDef> all = [
    AvatarDef(
      id: 'lucia',
      name: 'Lucia',
      motif: MedallionMotif.sun,
      base: Color(0xFF2A2036),
      emblem: Color(0xFFE9B75A),
      rim: Color(0xFFD9A441),
    ),
    AvatarDef(
      id: 'marco',
      name: 'Marco',
      motif: MedallionMotif.mask,
      base: Color(0xFF3A1B22),
      emblem: Color(0xFFE58A78),
      rim: Color(0xFFC7534F),
    ),
    AvatarDef(
      id: 'sofia',
      name: 'Sofia',
      motif: MedallionMotif.lyre,
      base: Color(0xFF1B2C3D),
      emblem: Color(0xFF9FC6DE),
      rim: Color(0xFF4A7FA8),
    ),
    AvatarDef(
      id: 'luca',
      name: 'Luca',
      motif: MedallionMotif.wave,
      base: Color(0xFF16302E),
      emblem: Color(0xFF6FD0C0),
      rim: Color(0xFF2AA89B),
    ),
    AvatarDef(
      id: 'giulia',
      name: 'Giulia',
      motif: MedallionMotif.olive,
      base: Color(0xFF223020),
      emblem: Color(0xFFA8C98A),
      rim: Color(0xFF5E8A4A),
    ),
    AvatarDef(
      id: 'enzo',
      name: 'Enzo',
      motif: MedallionMotif.anchor,
      base: Color(0xFF251E2E),
      emblem: Color(0xFFC5B6DE),
      rim: Color(0xFF7A6A9B),
    ),
    AvatarDef(
      id: 'rosa',
      name: 'Rosa',
      motif: MedallionMotif.arch,
      base: Color(0xFF35202A),
      emblem: Color(0xFFEBA79B),
      rim: Color(0xFFDF654B),
    ),
    AvatarDef(
      id: 'dario',
      name: 'Dario',
      motif: MedallionMotif.star,
      base: Color(0xFF1E2438),
      emblem: Color(0xFFF6DFA6),
      rim: Color(0xFF8A5F1C),
    ),
  ];

  static AvatarDef byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);

  /// Avatars offered to the human player.
  static List<AvatarDef> get selectable => all;
}
