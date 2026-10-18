import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/game/puzzle_engine.dart';
import 'package:puzzle_deslizante/game/puzzle_game_screen.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'Pieza 7 se desliza de su casilla al hueco, sin teletransportarse',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: PuzzleGameScreen(
            gridSize: 3,
            tileStyle: TileStyle.classic,
            animationsEnabled: true,
            storage: LocalStorage(),
            initialEngine: PuzzleEngine(
              gridSize: 3,
              initialBoard: [1, 2, 3, 4, 5, 6, 0, 7, 8],
            ),
          ),
        ),
      );
      await tester.pump();

      final tile = find.byKey(const Key('tile-7'));
      final startX = tester.getTopLeft(tile).dx;
      final animated = tester.widget<AnimatedPositioned>(
        find.byKey(const ValueKey<String>('positioned-7')),
      );
      expect(animated.duration, const Duration(milliseconds: 240));

      await tester.tap(tile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final middleX = tester.getTopLeft(tile).dx;
      await tester.pump(const Duration(milliseconds: 140));
      final endX = tester.getTopLeft(tile).dx;

      expect(middleX, lessThan(startX));
      expect(middleX, greaterThan(endX));
      expect(endX, lessThan(startX));
      final count = tester.widget<Text>(find.byKey(const Key('move-count')));
      expect(count.data, '1');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
