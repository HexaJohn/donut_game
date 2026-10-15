import 'dart:async';
import 'dart:io';

/// Calls [changed] with [path]'s contents whenever it's saved.
void watchFile(String path, void Function(String contents) changed) {
  final file = File(path);
  if (!file.existsSync()) return;
  Timer? settle;
  file.parent.watch().where((event) => event.path.endsWith(file.uri.pathSegments.last)).listen((_) {
    // Editors save in a few steps; read once they're done
    settle?.cancel();
    settle = Timer(const Duration(milliseconds: 150), () {
      try {
        changed(file.readAsStringSync());
      } catch (_) {}
    });
  });
}
