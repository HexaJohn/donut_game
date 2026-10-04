import 'dart:async';

import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:flutter/material.dart';

class Announcement {
  Announcement(this.title, {this.subtitle, this.urgent = false, this.icon});

  final String title;
  final String? subtitle;

  /// Something the local player needs to act on: shown longer and highlighted.
  final bool urgent;
  final Widget? icon;
}

/// Queues phase banners and shows them one at a time.
class Announcer extends ChangeNotifier {
  final List<Announcement> _queue = [];
  Announcement? _current;
  Timer? _timer;

  Announcement? get current => _current;

  void announce(Announcement announcement) {
    // Don't let stale news pile up behind something the player must act on
    if (_queue.length >= 2) _queue.removeWhere((element) => !element.urgent);
    _queue.add(announcement);
    if (_current == null) _next();
  }

  void _next() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }
    _current = _queue.removeAt(0);
    notifyListeners();
    final shownFor = _current!.urgent ? 2200 : (_queue.isEmpty ? 1700 : 1100);
    _timer = Timer(Duration(milliseconds: shownFor), _next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.announcer});

  final Announcer announcer;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: announcer,
      builder: (context, _) {
        final current = announcer.current;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(animation),
              child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(animation), child: child),
            ),
          ),
          child: current == null
              ? const SizedBox(key: ValueKey('none'), height: 1)
              : Center(key: ObjectKey(current), child: _BannerCard(announcement: current)),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    final urgent = announcement.urgent;
    final background = urgent ? colors.accent : theme.colorScheme.surface;
    final foreground = urgent
        ? (ThemeData.estimateBrightnessForColor(colors.accent) == Brightness.dark ? Colors.white : Colors.black)
        : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: (urgent ? colors.accent : Colors.black).withValues(alpha: 0.3), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (announcement.icon != null) ...[announcement.icon!, const SizedBox(width: 12)],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(announcement.title,
                  style: theme.textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800)),
              if (announcement.subtitle != null)
                Text(announcement.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: foreground.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}
