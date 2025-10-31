import 'dart:async';

import 'package:flclashx/common/common.dart';
import 'package:flclashx/providers/config.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
  });
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  _checkUpdate(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    final data = await commonScaffoldState?.loadingRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
    );
    globalState.appController.checkUpdateResultHandle(
      data: data,
      handleError: true,
    );
  }
  List<Widget> _buildThanksSection(BuildContext context) {
    return generateSection(
      separated: false,
      title: appLocalizations.thanks,
      items: [
        ListItem(
          title: const Text("legiz | for any ideas"),
          onTap: () {
            globalState.openUrl(
              "https://t.me/legiz_trashbag",
            );
          },
          trailing: const Icon(Icons.near_me),
        ),
        ListItem(
          title: const Text("x_kit_ | for refactor locale"),
          onTap: () {
            globalState.openUrl(
              "https://github.com/this-xkit",
            );
          },
          trailing: const Icon(Icons.near_me),
        ),
        ListItem(
          title: const Text("cool_coala | for any ideas"),
          onTap: () {
            globalState.openUrl(
              "https://github.com/coolcoala",
            );
          },
          trailing: const Icon(Icons.near_me),
        ),
      ],
    );
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    return generateSection(
      separated: false,
      title: appLocalizations.more,
      items: [
        ListItem(
          title: Text(appLocalizations.checkUpdate),
          onTap: () {
            _checkUpdate(context);
          },
          trailing: const Icon(Icons.update),
        ),
        ListItem(
          title: const Text("Telegram"),
          onTap: () {
            globalState.openUrl(
              "https://t.me/FlClashx",
            );
          },
          trailing: const Icon(Icons.insert_link),
        ),
        ListItem(
          title: Text(appLocalizations.project),
          onTap: () {
            globalState.openUrl(
              "https://github.com/$repository",
            );
          },
          trailing: const Icon(Icons.insert_link),
        ),
        ListItem(
          title: Text(appLocalizations.originalRepository),
          onTap: () {
            globalState.openUrl(
              "https://github.com/chen08209/FlClash",
            );
          },
          trailing: const Icon(Icons.insert_link),
        ),
        ListItem(
          title: Text(appLocalizations.core),
          onTap: () {
            globalState.openUrl(
              "https://github.com/chen08209/Clash.Meta/tree/FlClash",
            );
          },
          trailing: const Icon(Icons.insert_link),
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection() {
    const contributors = [
      Contributor(
        avatar: "assets/images/avatars/pluralplay.jpg",
        name: "pluralplay",
        link: "https://t.me/g33kar",
      ),
    ];
    return generateSection(
      separated: false,
      title: appLocalizations.otherContributors,
      items: [
        ListItem(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 24,
              children: [
                for (final contributor in contributors)
                  Avatar(
                    contributor: contributor,
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(builder: (_, ref, ___) {
              return _DeveloperModeDetector(
                child: Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          globalState.packageInfo.version,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        _CoreVersionWidget(),
                      ],
                    )
                  ],
                ),
                onEnterDeveloperMode: () {
                  ref.read(appSettingProvider.notifier).updateState(
                        (state) => state.copyWith(developerMode: true),
                      );
                  context.showNotifier(appLocalizations.developerModeEnableTip);
                },
              );
            }),
            const SizedBox(
              height: 24,
            ),
            Text(
              appLocalizations.desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(
        height: 12,
      ),
      ..._buildContributorsSection(),
      ..._buildThanksSection(context),
      ..._buildMoreSection(context),
    ];
    return Padding(
      padding: kMaterialListPadding.copyWith(
        top: 16,
        bottom: 16,
      ),
      child: generateListView(items),
    );
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({
    super.key,
    required this.contributor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircleAvatar(
              foregroundImage: AssetImage(
                contributor.avatar,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            contributor.name,
            style: context.textTheme.bodySmall,
          )
        ],
      ),
      onTap: () {
        globalState.openUrl(contributor.link);
      },
    );
  }
}

class _CoreVersionWidget extends StatelessWidget {
  const _CoreVersionWidget();

  @override
  Widget build(BuildContext context) {
    final coreVersion = globalState.coreVersion;
    if (coreVersion == null || coreVersion.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      'Core: $coreVersion',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.child,
    );
  }
}
