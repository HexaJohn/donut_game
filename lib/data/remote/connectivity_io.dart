import 'dart:io';

Future<bool?> checkInternet() async {
  try {
    final result = await InternetAddress.lookup('one.one.one.one').timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}
