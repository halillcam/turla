import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/profile/presentation/utils/profile_display.dart';

UserProfile _profile(String name) =>
    UserProfile(id: 'u1', email: 'a@b.c', fullName: name, role: UserRole.customer, isActive: true);

void main() {
  test('baş harfler: ad ve soyadın ilk harfi, Türkçe büyük harf', () {
    expect(_profile('ayşe yılmaz').initials, 'AY');
    expect(_profile('  İsmail  Çelik  ').initials, 'İÇ');
    expect(_profile('ilker').initials, 'İ');
    expect(_profile('Ali Veli Kaya').initials, 'AK');
    expect(_profile('').initials, '');
  });
}
