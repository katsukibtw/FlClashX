import 'package:flclashx/common/common.dart';
import 'package:flclashx/models/models.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/views/profiles/add_profile.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MetainfoWidget extends ConsumerWidget {
  const MetainfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = ref.watch(profilesProvider);
    final currentProfile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    if (allProfiles.isEmpty) {
      return CommonCard(
        onPressed: () {
          showExtend(
            context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: AddProfileView(
                  context: context,
                ),
                title: "${appLocalizations.add}${appLocalizations.profile}",
              );
            },
          );
        },
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text("Добавить профиль"),
              ],
            ),
          ),
        ),
      );
    }

    final subscriptionInfo = currentProfile?.subscriptionInfo;

    if (currentProfile == null || subscriptionInfo == null) {
      return const SizedBox.shrink();
    }

    final bool isUnlimitedTraffic = subscriptionInfo.total == 0;
    final bool isPerpetual = subscriptionInfo.expire == 0;
    final supportUrl = currentProfile.supportUrl;

    String daysLeft = '';
    if (!isPerpetual) {
      final expireDateTime =
          DateTime.fromMillisecondsSinceEpoch(subscriptionInfo.expire * 1000);
      final diff = expireDateTime.difference(DateTime.now()).inDays;
      // Only show days left if it's within 3 days
      if (diff >= 0 && diff <= 3) {
        daysLeft = diff.toString();
      }
    }

    return CommonCard(
      onPressed: null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            currentProfile.label ?? 'Профиль',
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (supportUrl != null && supportUrl.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              supportUrl.toLowerCase().contains('t.me')
                                  ? Icons.telegram
                                  : Icons.launch,
                            ),
                            iconSize: 34,
                            color: theme.colorScheme.primary,
                            onPressed: () {
                              globalState.openUrl(supportUrl);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.sync),
                          iconSize: 34,
                          color: theme.colorScheme.primary,
                          onPressed: () {
                            globalState.appController
                                .updateProfile(currentProfile);
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isUnlimitedTraffic)
                      Builder(builder: (context) {
                        final totalTraffic =
                            TrafficValue(value: subscriptionInfo.total);
                        final usedTrafficValue =
                            subscriptionInfo.upload + subscriptionInfo.download;
                        final usedTraffic =
                            TrafficValue(value: usedTrafficValue);

                        double progress = 0.0;
                        if (subscriptionInfo.total > 0) {
                          progress = usedTrafficValue / subscriptionInfo.total;
                        }
                        progress = progress.clamp(0.0, 1.0);

                        Color progressColor = Colors.green;
                        if (progress > 0.9) {
                          progressColor = Colors.red;
                        } else if (progress > 0.7) {
                          progressColor = Colors.orange;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appLocalizations.traffic} ${usedTraffic.showValue} ${usedTraffic.showUnit} / ${totalTraffic.showValue} ${totalTraffic.showUnit}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor),
                              ),
                            ),
                          ],
                        );
                      })
                    else
                      Text(
                        appLocalizations.trafficUnlimited,
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isPerpetual
                          ? appLocalizations.subscriptionEternal
                          : '${appLocalizations.expiresOn} ${DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(subscriptionInfo.expire * 1000))}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (!isPerpetual && daysLeft.isNotEmpty) ...[
                const VerticalDivider(width: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appLocalizations.remaining,
                      style: theme.textTheme.bodySmall,
                    ),
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        daysLeft,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      appLocalizations.days,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
