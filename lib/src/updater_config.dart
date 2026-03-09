// lib/src/updater_config.dart

/// Configuration for GithubApkUpdater.
///
/// Example:
/// ```dart
/// final config = UpdaterConfig(
///   githubUsername: 'Mans610',
///   githubRepo: 'supperclubApp',
/// );
/// ```
class UpdaterConfig {
  /// Your GitHub username
  final String githubUsername;

  /// Your GitHub repository name
  final String githubRepo;

  /// Branch where version.json is stored (default: 'main')
  final String branch;

  /// Dialog title shown to user (default: 'Update Available')
  final String dialogTitle;

  /// Text for the update button (default: 'Update Now')
  final String updateButtonText;

  /// Text for the dismiss button (default: 'Later')
  final String laterButtonText;

  /// Check update on every app launch (default: true)
  final bool checkOnLaunch;

  /// Built version.json URL — auto-generated, no need to set manually
  String get versionJsonUrl =>
      'https://raw.githubusercontent.com/$githubUsername/$githubRepo/$branch/version.json';

  const UpdaterConfig({
    required this.githubUsername,
    required this.githubRepo,
    this.branch = 'main',
    this.dialogTitle = 'Update Available',
    this.updateButtonText = 'Update Now',
    this.laterButtonText = 'Later',
    this.checkOnLaunch = true,
  });
}
