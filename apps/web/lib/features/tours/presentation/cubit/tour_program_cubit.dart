import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/program_day.dart';
import '../../domain/repositories/tour_admin_repository.dart';

/// Gün gün tur programı düzenleyicisi. Düzenlemeler yerelde tutulur,
/// "Kaydet" ile tek istekte sunucuya yazılır.
class TourProgramCubit extends Cubit<TourProgramState> {
  TourProgramCubit({required this.tourId, required this._repository})
    : super(const TourProgramState());

  final String tourId;
  final TourAdminRepository _repository;
  int _nextKey = 0;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final days = await _repository.getProgram(tourId);
      emit(TourProgramState(status: LoadStatus.ready, items: _wrap(days), savedDays: days));
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  void addDay() => _setItems([...state.items, ProgramDayItem(_nextKey++, const ProgramDay())]);

  void removeDay(int index) => _setItems([...state.items]..removeAt(index));

  /// [delta] -1 yukarı, +1 aşağı.
  void moveDay(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= state.items.length) return;
    final items = [...state.items];
    final item = items.removeAt(index);
    items.insert(target, item);
    _setItems(items);
  }

  void updateTitle(int index, String title) =>
      _updateDay(index, (day) => day.copyWith(title: title));

  /// Çok satırlı metin: her satır bir etkinlik.
  void updateActivities(int index, String multilineText) =>
      _updateDay(index, (day) => day.copyWith(activities: multilineText.split('\n')));

  Future<ActionResult<List<ProgramDay>>> save() async {
    emit(state.copyWith(isSaving: true));
    final result = await runAction(() => _repository.saveProgram(tourId, state.days));
    final saved = result.value;
    emit(
      saved == null
          ? state.copyWith(isSaving: false)
          : TourProgramState(status: LoadStatus.ready, items: _wrap(saved), savedDays: saved),
    );
    return result;
  }

  void _updateDay(int index, ProgramDay Function(ProgramDay) change) {
    final items = [...state.items];
    items[index] = ProgramDayItem(items[index].key, change(items[index].day));
    _setItems(items);
  }

  void _setItems(List<ProgramDayItem> items) => emit(state.copyWith(items: items));

  List<ProgramDayItem> _wrap(List<ProgramDay> days) => [
    for (final day in days) ProgramDayItem(_nextKey++, day),
  ];
}

/// Düzenleyicide bir gün. [key] sadece arayüzdeki alanları sıralama
/// değişse de doğru günle eşleştirmek içindir; sunucuya gitmez.
class ProgramDayItem extends Equatable {
  const ProgramDayItem(this.key, this.day);

  final int key;
  final ProgramDay day;

  @override
  List<Object?> get props => [key, day];
}

final class TourProgramState extends Equatable {
  const TourProgramState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.savedDays = const [],
    this.loadFailure,
    this.isSaving = false,
  });

  final LoadStatus status;
  final List<ProgramDayItem> items;

  /// Sunucudaki son kayıtlı program (değişiklik var mı kontrolü için).
  final List<ProgramDay> savedDays;
  final PanelFailureReason? loadFailure;
  final bool isSaving;

  List<ProgramDay> get days => [for (final item in items) item.day];

  /// Kaydedilmemiş değişiklik var mı? Boş satırlar fark sayılmaz.
  bool get isDirty {
    if (items.length != savedDays.length) return true;
    for (var i = 0; i < items.length; i++) {
      if (!_sameDay(items[i].day, savedDays[i])) return true;
    }
    return false;
  }

  static bool _sameDay(ProgramDay a, ProgramDay b) {
    List<String> clean(ProgramDay d) => [
      for (final x in d.activities)
        if (x.trim().isNotEmpty) x.trim(),
    ];
    final ca = clean(a);
    final cb = clean(b);
    if (a.title.trim() != b.title.trim() || ca.length != cb.length) return false;
    for (var i = 0; i < ca.length; i++) {
      if (ca[i] != cb[i]) return false;
    }
    return true;
  }

  TourProgramState copyWith({
    LoadStatus? status,
    List<ProgramDayItem>? items,
    PanelFailureReason? loadFailure,
    bool? isSaving,
  }) => TourProgramState(
    status: status ?? this.status,
    items: items ?? this.items,
    savedDays: savedDays,
    loadFailure: loadFailure ?? this.loadFailure,
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => [status, items, savedDays, loadFailure, isSaving];
}
