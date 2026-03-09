// lib/src/updater_dialog.dart
import 'package:flutter/material.dart';
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

  Future<void> _download() async {
    setState(() => _downloading = true);
    final uri = Uri.parse(widget.info.apkUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[GithubApkUpdater] Download failed: $e');
    }
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = widget.info;
    final config = widget.config;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.system_update_rounded,
                      color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    config.dialogTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _VersionChip(
                          label: 'Current', version: info.currentVersion),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                      _VersionChip(
                          label: 'New',
                          version: info.latestVersion,
                          highlight: true,
                          color: theme.colorScheme.primary),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Release notes
                  Text(
                    info.releaseNotes,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                        fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      if (!info.forceUpdate) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(config.laterButtonText),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: info.forceUpdate ? 1 : 0,
                        child: ElevatedButton(
                          onPressed: _downloading ? null : _download,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _downloading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.download_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Text(config.updateButtonText),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String version;
  final bool highlight;
  final Color? color;

  const _VersionChip({
    required this.label,
    required this.version,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: highlight
                ? (color ?? Colors.blue).withOpacity(0.12)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: highlight
                ? Border.all(color: (color ?? Colors.blue).withOpacity(0.4))
                : null,
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? (color ?? Colors.blue) : null,
            ),
          ),
        ),
      ],
    );
  }
}
