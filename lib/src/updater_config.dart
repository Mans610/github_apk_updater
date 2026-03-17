// lib/src/updater_config.dart
import 'package:flutter/material.dart';

import 'update_info.dart';

/// Builder for a completely custom update dialog.
typedef UpdateDialogBuilder = Widget Function(
  BuildContext context,
  UpdateInfo updateInfo,
);

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

  /// Text for the skip button (default: 'Skip This Version')
  final String skipButtonText;

  /// Check update on every app launch (default: true)
  final bool checkOnLaunch;

  /// Allow user to skip this specific version forever (default: false)
  final bool allowSkip;

  /// Optional builder to return a completely custom dialog widget.
  final UpdateDialogBuilder? dialogBuilder;

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
    this.skipButtonText = 'Skip This Version',
    this.checkOnLaunch = true,
    this.allowSkip = false,
    this.dialogBuilder,
  });
}
