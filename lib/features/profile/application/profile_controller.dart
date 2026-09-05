import 'dart:async';

import 'package:get/get.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/remote_profile.dart';
import 'profile_repository.dart';

/// The signed-in player's server profile, kept in step with the session.
///
/// `profile` is `null` whenever there is no session or no backend; screens
/// then draw the local placeholder exactly as before. It never fabricates a
/// row — every value shown came from a real query.
class ProfileController extends GetxController {
  ProfileController(this._repository, this._session);

  final ProfileRepository _repository;
  final SessionController _session;

  final Rx<RemoteProfile?> profile = Rx<RemoteProfile?>(null);
  final Rx<RemotePlayerStats?> stats = Rx<RemotePlayerStats?>(null);

  /// Badges the SERVER unlocked (online play). Disjoint from the local
  /// offline list in [StatsController]; screens show the union.
  final RxSet<String> achievements = <String>{}.obs;

  /// Server badges that appeared since the previous load — what an online
  /// result screen celebrates.
  final RxList<String> newAchievements = <String>[].obs;
  final RxBool loading = false.obs;
  final Rx<ProfileError?> lastError = Rx<ProfileError?>(null);

  Worker? _worker;

  bool get hasRemoteProfile => profile.value != null;

  @override
  void onInit() {
    super.onInit();
    _worker = ever<AuthSession?>(_session.session, _onSession);
    _onSession(_session.current);
  }

  void _onSession(AuthSession? session) {
    if (session == null) {
      profile.value = null;
      stats.value = null;
      achievements.clear();
      newAchievements.clear();
      return;
    }
    unawaited(reload());
  }

  Future<void> reload() async {
    final session = _session.current;
    if (session == null) return;
    loading.value = true;
    try {
      // The profile row is created by a database trigger the moment the auth
      // user exists; a brand-new sign-up can race it by a few milliseconds.
      var remote = await _repository.fetch(session.userId);
      if (remote == null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        remote = await _repository.fetch(session.userId);
      }
      // Guard against a sign-out that happened while we were waiting.
      if (_session.current?.userId != session.userId) return;
      profile.value = remote;
      stats.value = await _repository.fetchStats(session.userId);
      final badges = await _repository.fetchAchievements(session.userId);
      final fresh = badges.where((id) => !achievements.contains(id)).toList();
      if (achievements.isNotEmpty || newAchievements.isNotEmpty) {
        newAchievements.addAll(fresh);
      }
      achievements
        ..clear()
        ..addAll(badges);
      lastError.value = null;
      unawaited(_repository.touchPresence());
    } on ProfileException catch (error) {
      lastError.value = error.error;
    } finally {
      loading.value = false;
    }
  }

  bool hasAchievement(String id) => achievements.contains(id);

  List<String> drainNewAchievements() {
    final list = List<String>.of(newAchievements);
    newAchievements.clear();
    return list;
  }

  /// Saves nickname + avatar to the server. Throws [ProfileException].
  Future<void> updateProfile({
    required String nickname,
    required String avatarId,
  }) async {
    final session = _session.current;
    if (session == null) {
      throw const ProfileException(ProfileError.unavailable);
    }
    profile.value = await _repository.updateMine(
      userId: session.userId,
      nickname: nickname,
      avatarId: avatarId,
    );
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}
