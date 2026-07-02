import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard white card matching the HTML `.card` class.
class SimCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SimCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SimColors.card,
        border: Border.all(color: SimColors.line),
        borderRadius: BorderRadius.circular(SimTheme.radius),
      ),
      child: child,
    );
  }
}

/// Dark result card matching `.result-card`.
class ResultCard extends StatelessWidget {
  final Widget child;

  const ResultCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SimColors.ink,
        borderRadius: BorderRadius.circular(SimTheme.radius),
      ),
      child: child,
    );
  }
}

/// A single result row in a dark card.
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const ResultRow({super.key, required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(30))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 13.5, color: SimColors.heroSub)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: numStyle(
              size: isTotal ? 16 : 14,
              color: isTotal ? SimColors.brassLight : SimColors.heroText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card title + subtitle header.
class CardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color titleColor;

  const CardHeader({super.key, required this.title, this.subtitle, this.titleColor = SimColors.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600, color: titleColor)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: SimColors.muted)),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}
