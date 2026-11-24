import 'dart:async';

import 'package:flutter/foundation.dart';

/// Verilen akışlardan biri her değiştiğinde router'ın yönlendirmeyi yeniden
/// değerlendirmesini sağlar.
class StreamRefreshListenable extends ChangeNotifier {
  StreamRefreshListenable(List<Stream<dynamic>> streams) {
    _subscriptions = [for (final stream in streams) stream.listen((_) => notifyListeners())];
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
