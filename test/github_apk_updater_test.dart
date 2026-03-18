import 'package:flutter_test/flutter_test.dart';

import 'package:github_apk_updater/github_apk_updater.dart';

void main() {
  test('Creates UpdaterConfig correctly', () {
    final config = UpdaterConfig(
      githubUsername: 'Mans610',
      githubRepo: 'supperclubApp',
    );
    expect(config.githubUsername, 'Mans610');
    expect(config.githubRepo, 'supperclubApp');
    expect(config.versionJsonUrl,
        'https://raw.githubusercontent.com/Mans610/supperclubApp/main/version.json');
  });
}
