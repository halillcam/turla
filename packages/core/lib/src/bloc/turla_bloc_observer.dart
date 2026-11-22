import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Geliştirme sırasında Bloc hatalarını ve geçişlerini konsola yazar.
class TurlaBlocObserver extends BlocObserver {
  const TurlaBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[${bloc.runtimeType}] hata: $error');
    }
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    if (kDebugMode) {
      debugPrint(
        '[${bloc.runtimeType}] ${transition.event.runtimeType} → '
        '${transition.nextState.runtimeType}',
      );
    }
    super.onTransition(bloc, transition);
  }
}
