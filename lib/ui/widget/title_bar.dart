import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

const double titleBarHeight = 40;

/// Custom window chrome: drag area, title, an optional trailing widget and
/// the window buttons. Desktop only: phones and browsers have their own
/// chrome, so there it takes no space at all, except on screens with
/// [onBack], which get a slim header with a back arrow so there's a way out.
class DonutTitleBar extends StatefulWidget {
  const DonutTitleBar(
      {super.key, this.title, this.trailing, this.onBack, this.transparent = false, this.solid = true, this.foreground});

  final String? title;
  final Widget? trailing;

  /// Leaves the screen: a close button in the bar on desktop, a back arrow
  /// elsewhere.
  final VoidCallback? onBack;

  /// For splash screens: no background, logo or title.
  final bool transparent;

  /// False draws the bar straight over whatever is behind it.
  final bool solid;
  final Color? foreground;

  @override
  State<DonutTitleBar> createState() => _DonutTitleBarState();
}

class _DonutTitleBarState extends State<DonutTitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (isDesktop) {
      windowManager.addListener(this);
      windowManager.isMaximized().then((value) {
        if (mounted) setState(() => _maximized = value);
      });
    }
  }

  @override
  void dispose() {
    if (isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    if (!isDesktop) {
      final back = widget.onBack;
      if (back == null) return const SizedBox.shrink();
      return Container(
        height: 48,
        color: widget.solid ? colors.chrome : Colors.transparent,
        child: Row(children: [
          IconButton(tooltip: appBack(), onPressed: back, icon: const Icon(Icons.arrow_back_rounded)),
          if (widget.title != null)
            Expanded(
              child: Text(widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            )
          else
            const Spacer(),
          if (widget.trailing != null) ...[widget.trailing!, const SizedBox(width: 8)],
        ]),
      );
    }
    final foreground = widget.foreground ?? theme.colorScheme.onSurface;
    // Window buttons pick their colours from the background behind them
    final behind = widget.transparent
        ? (foreground.computeLuminance() > 0.5 ? Colors.black : Colors.white)
        : (widget.solid ? colors.chrome : theme.scaffoldBackgroundColor);
    final brightness = ThemeData.estimateBrightnessForColor(behind);
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    Widget content = Row(
      children: [
        // Leave room for the macOS traffic lights
        SizedBox(width: isMac && isDesktop ? 78 : 12),
        if (!widget.transparent) ...[
          DonutLogo(size: 22, frosting: theme.colorScheme.primary, shadow: false),
          const SizedBox(width: 8),
          Text(appName(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: foreground)),
          if (widget.title != null) Text('  ·  ', style: TextStyle(color: foreground.withValues(alpha: 0.4))),
        ],
        // Takes the remaining width so the trailing widget hugs the right edge
        Expanded(
          child: Text(widget.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground.withValues(alpha: 0.7))),
        ),
        if (widget.trailing != null) ...[widget.trailing!, const SizedBox(width: 8)],
        if (widget.onBack != null)
          IconButton(tooltip: appBack(), icon: const Icon(Icons.close_rounded), onPressed: widget.onBack),
      ],
    );

    if (isDesktop) content = DragToMoveArea(child: content);

    return Container(
      height: titleBarHeight,
      color: widget.transparent || !widget.solid ? Colors.transparent : colors.chrome,
      child: Row(
        children: [
          Expanded(child: content),
          if (isDesktop && !isMac) ...[
            WindowCaptionButton.minimize(brightness: brightness, onPressed: windowManager.minimize),
            _maximized
                ? WindowCaptionButton.unmaximize(brightness: brightness, onPressed: windowManager.unmaximize)
                : WindowCaptionButton.maximize(brightness: brightness, onPressed: windowManager.maximize),
            WindowCaptionButton.close(brightness: brightness, onPressed: windowManager.close),
          ],
        ],
      ),
    );
  }
}
