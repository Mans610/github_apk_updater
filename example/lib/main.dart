import 'package:flutter/material.dart';
import 'package:github_apk_updater/github_apk_updater.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _updater = GithubApkUpdater(
    config: const UpdaterConfig(
      githubUsername: 'your_username',
      githubRepo: 'your_repo',
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updater.check(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _updater.check(context),
          child: const Text('Check for Updates'),
        ),
      ),
    );
  }
}
