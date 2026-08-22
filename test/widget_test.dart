import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/app.dart';
import 'package:lifelog/core/db/database.dart';
import 'package:lifelog/features/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
  );
}

void main() {
  testWidgets('空状态展示建议预设，点击后首页出现卡片', (tester) async {
    final container = await _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LifelogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 空状态
    expect(find.text('还没有计数器'), findsOneWidget);
    expect(find.text('💧 喝水'), findsOneWidget);

    // 点击预设 → 出现卡片
    await tester.tap(find.text('💧 喝水'));
    await tester.pumpAndSettle();

    expect(find.text('还没有计数器'), findsNothing);
    expect(find.text('喝水'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('今日 0/8'), findsOneWidget);
  });
}
