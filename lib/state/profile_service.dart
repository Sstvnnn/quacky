import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String displayName;
  final int? age;
  final String? gender;
  final String? avatarUrl;
  final bool hasCompletedSimulation;
  final String status;
  final String role;

  Profile({
    required this.id,
    required this.displayName,
    this.age,
    this.gender,
    this.avatarUrl,
    required this.hasCompletedSimulation,
    required this.status,
    required this.role,
  });

  bool get isSar => role == 'sar';

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: (m['display_name'] as String?) ?? 'Friend',
        age: m['age'] as int?,
        gender: m['gender'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        hasCompletedSimulation:
            (m['has_completed_simulation'] as bool?) ?? false,
        status: (m['status'] as String?) ?? 'safe',
        role: (m['role'] as String?) ?? 'user',
      );
}

class ProfileService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String? get _uid => _client.auth.currentUser?.id;

  static String _metadataName() =>
      (_client.auth.currentUser?.userMetadata?['display_name'] as String?) ??
      'Friend';

  static Future<void> saveProfile({
    required String displayName,
    required int age,
    required String gender,
    Uint8List? avatarBytes,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    String? avatarUrl;
    if (avatarBytes != null) {
      final path = '$uid/avatar.jpg';
      await _client.storage.from('avatars').uploadBinary(
            path,
            avatarBytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
      avatarUrl = _client.storage.from('avatars').getPublicUrl(path);
    }

    await _client.from('profiles').upsert({
      'id': uid,
      'display_name': displayName,
      'age': age,
      'gender': gender,
      'avatar_url': ?avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Profile?> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  static Future<void> markSimulationComplete() async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('profiles').upsert({
      'id': uid,
      'display_name': _metadataName(),
      'has_completed_simulation': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> setStatus(String status) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('profiles').upsert({
      'id': uid,
      'display_name': _metadataName(),
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> setLocation({
    required String source,
    required String note,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('profiles').upsert({
      'id': uid,
      'display_name': _metadataName(),
      'location_source': source,
      'location_note': note,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
