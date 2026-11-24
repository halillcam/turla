import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_web/core/bloc/load_status.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/tours/domain/entities/program_day.dart';
import 'package:turla_web/features/tours/domain/repositories/tour_admin_repository.dart';
import 'package:turla_web/features/tours/presentation/cubit/tour_program_cubit.dart';

class _MockRepo extends Mock implements TourAdminRepository {}

void main() {
  late _MockRepo repo;
  late TourProgramCubit cubit;

  const saved = [
    ProgramDay(title: 'Göksun', activities: ['Kahvaltı']),
    ProgramDay(title: 'Dönüş'),
  ];

  setUp(() async {
    repo = _MockRepo();
    when(() => repo.getProgram('t1')).thenAnswer((_) async => saved);
    cubit = TourProgramCubit(tourId: 't1', repository: repo);
    await cubit.load();
  });

  tearDown(() => cubit.close());

  test('yüklenince değişiklik yok sayılır', () {
    expect(cubit.state.status, LoadStatus.ready);
    expect(cubit.state.days, saved);
    expect(cubit.state.isDirty, isFalse);
  });

  test('gün ekleme / silme / taşıma, anahtarlar günle birlikte gider', () {
    cubit.addDay();
    expect(cubit.state.items.length, 3);
    expect(cubit.state.isDirty, isTrue);

    final firstKey = cubit.state.items[0].key;
    cubit.moveDay(0, 1);
    expect(cubit.state.days[1].title, 'Göksun');
    expect(cubit.state.items[1].key, firstKey);

    cubit.moveDay(0, -1); // sınır dışı: değişmez
    expect(cubit.state.days[0].title, 'Dönüş');

    cubit.removeDay(2);
    expect(cubit.state.items.length, 2);
  });

  test('etkinlikler satır satır; boş satır ve boşluk fark sayılmaz', () {
    cubit.updateActivities(0, 'Kahvaltı\n\n  ');
    expect(cubit.state.days[0].activities, ['Kahvaltı', '', '  ']);
    expect(cubit.state.isDirty, isFalse);

    cubit.updateActivities(0, 'Kahvaltı\nYürüyüş');
    expect(cubit.state.isDirty, isTrue);
  });

  test('kaydetme güncel günleri gönderir ve sunucu sonucunu kayıtlı kabul eder', () async {
    cubit.updateTitle(1, 'Eve dönüş');
    final expected = [saved[0], const ProgramDay(title: 'Eve dönüş')];
    when(() => repo.saveProgram('t1', expected)).thenAnswer((_) async => expected);

    final result = await cubit.save();

    expect(result.isSuccess, isTrue);
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.isSaving, isFalse);
    verify(() => repo.saveProgram('t1', expected)).called(1);
  });

  test('kaydetme hatasında düzenlemeler korunur', () async {
    cubit.addDay();
    when(
      () => repo.saveProgram(any(), any()),
    ).thenThrow(const PanelFailure(PanelFailureReason.notAllowed));

    final result = await cubit.save();

    expect(result.failure, PanelFailureReason.notAllowed);
    expect(cubit.state.items.length, 3);
    expect(cubit.state.isDirty, isTrue);
  });
}
