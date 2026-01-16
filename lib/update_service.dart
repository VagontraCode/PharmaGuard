import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String _owner = 'VagontraCode';
  static const String _repo = 'PharmaGuard';

  Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdate = false,
  }) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      // 2. Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String tagName = data['tag_name'];
        // Remove 'v' prefix if present (e.g. v1.0.2 -> 1.0.2)
        final cleanTag = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;
        final latestVersion = Version.parse(cleanTag);

        if (latestVersion > currentVersion) {
          if (context.mounted) {
            _showUpdateDialog(context, data, latestVersion.toString());
          }
        } else {
          if (showNoUpdate && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Vous êtes à jour !')));
          }
        }
      } else {
        debugPrint('GitHub API Error: ${response.statusCode}');
        if (showNoUpdate && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de vérifier les mises à jour'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> releaseData,
    String version,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mise à jour disponible ($version)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Une nouvelle version est disponible.'),
              const SizedBox(height: 10),
              const Text(
                'Notes de version :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(releaseData['body'] ?? 'Aucune description.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadUpdate(context, releaseData);
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate(
    BuildContext context,
    Map<String, dynamic> releaseData,
  ) async {
    String? downloadUrl;
    String? fileName;
    final List assets = releaseData['assets'] ?? [];

    // Try to find the correct asset for the platform
    if (Platform.isAndroid) {
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );
      downloadUrl = apkAsset?['browser_download_url'];
      fileName = apkAsset?['name'];
    } else if (Platform.isWindows) {
      final exeAsset = assets.firstWhere(
        (asset) =>
            asset['name'].toString().endsWith('.exe') ||
            asset['name'].toString().endsWith('.msix'),
        orElse: () => null,
      );
      downloadUrl = exeAsset?['browser_download_url'];
      fileName = exeAsset?['name'];
    } else if (Platform.isLinux) {
      final linuxAsset = assets.firstWhere(
        (asset) =>
            asset['name'].toString().endsWith('.AppImage') ||
            asset['name'].toString().endsWith('.deb'),
        orElse: () => null,
      );
      downloadUrl = linuxAsset?['browser_download_url'];
      fileName = linuxAsset?['name'];
    }

    // Fallback to the release page HTML URL if no specific asset found
    if (downloadUrl == null) {
      downloadUrl = releaseData['html_url'];
      if (downloadUrl != null) {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DownloadDialog(
          url: downloadUrl!,
          fileName: fileName ?? 'update_package',
        ),
      );
    }
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const _DownloadDialog({required this.url, required this.fileName});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  String _status = 'Initialisation...';
  String? _errorMessage;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${widget.fileName}';
      _filePath = savePath;

      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int received = 0;

      final file = File(savePath);
      final sink = file.openWrite();

      await response.stream
          .listen(
            (chunk) {
              received += chunk.length;
              sink.add(chunk);
              if (mounted && contentLength > 0) {
                setState(() {
                  _progress = received / contentLength;
                  _status =
                      '${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(contentLength / 1024 / 1024).toStringAsFixed(1)} MB';
                });
              }
            },
            onDone: () async {
              await sink.close();
              if (mounted) {
                setState(() {
                  _status = 'Téléchargement terminé';
                });
                _installUpdate();
              }
            },
            onError: (e) {
              sink.close();
              throw e;
            },
            cancelOnError: true,
          )
          .asFuture();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
        });
      }
    }
  }

  Future<void> _installUpdate() async {
    if (_filePath != null) {
      final result = await OpenFilex.open(_filePath!);
      if (result.type != ResultType.done) {
        if (mounted) {
          setState(() {
            _errorMessage = "Erreur d'installation: ${result.message}";
          });
        }
      } else {
        // Close dialog if successful launch
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mise à jour'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red))
          else ...[
            Text(_status),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress),
          ],
        ],
      ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Masquer'),
          ),
      ],
    );
  }
}
