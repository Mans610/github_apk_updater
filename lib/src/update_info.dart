// lib/src/update_info.dart
import 'package:pub_semver/pub_semver.dart';

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

  factory UpdateInfo.fromJson(
      Map<String, dynamic> json, String currentVersion) {
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
      // Use pub_semver for reliable semantic version comparison
      final latestSemVer = Version.parse(latest);
      final currentSemVer = Version.parse(current);
      return latestSemVer > currentSemVer;
    } catch (_) {
      // Fallback to basic string comparison if parsing fails (e.g. invalid version tags)
      return latest.compareTo(current) > 0;
    }
  }
}
