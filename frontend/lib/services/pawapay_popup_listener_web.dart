import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

typedef PawapayMessageCallback = void Function(Map<String, dynamic> payload);

void Function() registerPawapayMessageListener(PawapayMessageCallback callback) {
  final StreamSubscription<html.MessageEvent> subscription =
      html.window.onMessage.listen((event) {
    final dynamic rawData = event.data;

    Map<String, dynamic>? parsed;
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
        } else if (decoded is Map) {
          parsed = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        parsed = null;
      }
    } else if (rawData is Map) {
      parsed = rawData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (parsed == null) return;
    if (parsed['source']?.toString() != 'pawapay') return;

    callback(parsed);
  });

  return () {
    subscription.cancel();
  };
}
