import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondaryHeaderSliver extends StatelessWidget {
  final String title;
  final String subtitle;
  final String infoLabel;
  final IconData infoIcon;
  final Widget? trailing;

  const SecondaryHeaderSliver({
    super.key,
    required this.title,
    required this.subtitle,
    required this.infoLabel,
    required this.infoIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverMainAxisGroup(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          border: null,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          leading: Navigator.of(context).canPop()
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Icon(CupertinoIcons.back, size: 22),
                )
              : null,
          trailing: trailing,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.28,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        infoIcon,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          infoLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
