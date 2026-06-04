import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/user.dart';

void main() {
  test('User.fromJson reads the documented shape', () {
    final json = {
      'id': '9b7c6df0-1234-4abc-9def-aaaaaaaaaaaa',
      'name': 'سعد القاضي',
      'email': 'demo@mishkat.local',
      'email_verified': true,
      'birth_year': 2010,
      'locale': 'ar',
      'is_active': true,
      'is_pending_deletion': false,
      'last_seen_at': '2026-05-20T09:15:23+03:00',
      'created_at': '2026-01-12T18:42:00+03:00',
    };

    final u = User.fromJson(json);
    expect(u.id, '9b7c6df0-1234-4abc-9def-aaaaaaaaaaaa');
    expect(u.name, 'سعد القاضي');
    expect(u.email, 'demo@mishkat.local');
    expect(u.locale, 'ar');
    expect(u.birthYear, 2010);
    expect(u.emailVerified, true);
    expect(u.isPendingDeletion, false);
  });

  test('User.fromJson tolerates missing optional fields', () {
    final u = User.fromJson({'id': 'x', 'name': 'y', 'email': 'z@z.z'});
    expect(u.locale, 'ar');
    expect(u.birthYear, isNull);
  });
}
