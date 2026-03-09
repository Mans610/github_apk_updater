// lib/src/update_info.dart
import 'dart:convert';

/// Represents info fetched from version.json on GitHub
class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final bool forceUpdate;
  final String releaseNotes;
  final String currentVersion;

  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.currentVersion,
  });

  bool get hasUpdate => _isNewer(latestVersion, currentVersion);

  factory UpdateInfo.fromJson(Map<String, dynamic> json, String currentVersion) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? '0.0.0',
      apkUrl: json['apk_url'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      releaseNotes: json['release_notes'] ?? 'A new version is available.',
      currentVersion: currentVersion,
    );
  }

  static bool _isNewer(String latest, String current) {
    try {
      final l = latest.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final lv = i < l.length ? l[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
    } catch (_) {}
    return false;
  }
}
