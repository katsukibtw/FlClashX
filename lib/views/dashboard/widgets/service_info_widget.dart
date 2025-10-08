import 'package:flclashx/common/common.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceInfoWidget extends ConsumerWidget {
  const ServiceInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return const SizedBox.shrink();
    }

    final serviceName = profile.serviceName;
    final supportUrl = profile.supportUrl;

    if (serviceName == null || serviceName.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: (supportUrl != null && supportUrl.isNotEmpty)
            ? () {
                globalState.openUrl(supportUrl);
              }
            : null,
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(
            top: 8,
            bottom: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.contact_mail,
                      size: 28,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        serviceName,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (supportUrl != null && supportUrl.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: 28,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
