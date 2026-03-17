// lib/src/updater_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_info.dart';
import 'updater_config.dart';

/// Shows the built-in update dialog.
/// Called automatically by [GithubApkUpdater.check()].
void showUpdateDialog(
  BuildContext context, {
  required UpdateInfo info,
  required UpdaterConfig config,
}) {
  showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (_) => _UpdateDialog(info: info, config: config),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final UpdaterConfig config;

  const _UpdateDialog({required this.info, required this.config});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _downloading = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'github_apk_updater_skipped_version', widget.info.latestVersion);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = null;
    });

    final uri = Uri.parse(widget.info.apkUrl);

    try {
      // 1. Get Temporary Directory
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update_${widget.info.latestVersion}.apk';
      final file = File(filePath);

      // 2. Stream Download
      final request = http.Request('GET', uri);
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _progress = receivedBytes / totalBytes;
          });
        }
      }
      await sink.close();

      // 3. Open APK for install
      if (mounted) setState(() => _downloading = false);
      final result = await OpenFilex.open(filePath);

      // 4. Fallback if OpenFilex fails
      if (result.type != ResultType.done) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[GithubApkUpdater] Download failed: $e');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (mounted) {
      setState(() {
        _downloading = false;
        _progress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = widget.info;
    final config = widget.config;

    return PopScope(
      canPop: !info.forceUpdate,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: theme.colorScheme.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  config.dialogTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Version Info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _VersionColumn(
                        label: 'Current',
                        version: info.currentVersion,
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      _VersionColumn(
                        label: 'New',
                        version: info.latestVersion,
                        isNew: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Release Notes
                if (info.releaseNotes.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        info.releaseNotes,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (!info.forceUpdate && !config.allowSkip) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            config.laterButtonText,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _downloading ? null : _download,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _downloading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      value: _progress,
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _progress != null
                                        ? '${(_progress! * 100).toInt()}%'
                                        : 'Starting...',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                config.updateButtonText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),

                // Secondary Row for Skip & Later (if allowSkip is enabled)
                if (!info.forceUpdate && config.allowSkip) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            config.laterButtonText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: theme.colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            config.skipButtonText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionColumn extends StatelessWidget {
  final String label;
  final String version;
  final bool isNew;

  const _VersionColumn({
    required this.label,
    required this.version,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
            color: isNew
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
