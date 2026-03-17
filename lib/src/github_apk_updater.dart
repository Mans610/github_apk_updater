// lib/src/github_apk_updater.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'updater_config.dart';
import 'update_info.dart';
import 'updater_dialog.dart';

class GithubApkUpdater {
  final UpdaterConfig config;

  GithubApkUpdater({required this.config});

  // ─── Simple one-line usage ───────────────────────────────────────────────

  /// Call this in your initState — it does everything automatically.
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   GithubApkUpdater(config: config).check(context);
  /// }
  /// ```
  Future<void> check(BuildContext context) async {
    final info = await _fetchUpdateInfo();
    if (info == null) return;
    if (!info.hasUpdate) return;

    if (!info.forceUpdate && config.allowSkip) {
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString('github_apk_updater_skipped_version');
      if (skippedVersion == info.latestVersion) {
        return; // User explicitly skipped this update
      }
    }

    if (context.mounted) {
      if (config.dialogBuilder != null) {
        showDialog(
          context: context,
          barrierDismissible: !info.forceUpdate,
          builder: (ctx) => config.dialogBuilder!(ctx, info),
        );
      } else {
        showUpdateDialog(context, info: info, config: config);
      }
    }
  }

  // ─── Manual / advanced usage ─────────────────────────────────────────────

  /// Returns update info without showing dialog.
  /// Use this if you want custom UI.
  ///
  /// ```dart
  /// final info = await GithubApkUpdater(config: config).getUpdateInfo();
  /// if (info != null && info.hasUpdate) {
  ///   // your custom UI
  /// }
  /// ```
  Future<UpdateInfo?> getUpdateInfo() => _fetchUpdateInfo();
  
  // ─── Internal ─────────────────────────────────────────────────────────────
  
  Future<UpdateInfo?> _fetchUpdateInfo() async {
    try {
      final response = await http
          .get(Uri.parse(config.versionJsonUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final packageInfo = await PackageInfo.fromPlatform();

      return UpdateInfo.fromJson(data, packageInfo.version);
    } catch (e) {
      debugPrint('[GithubApkUpdater] Check failed: $e');
      return null;
    }
  }
}
