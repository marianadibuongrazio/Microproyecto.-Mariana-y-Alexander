import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/game/puzzle_engine.dart';
import 'package:puzzle_deslizante/game/puzzle_game_screen.dart';
import 'package:puzzle_deslizante/main.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';
import 'package:puzzle_deslizante/theme/app_colors.dart';
import 'package:puzzle_deslizante/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('El selector usa la paleta y conserva la navegación', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Espera a que termine el Splash y la entrada del menú.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final play = find.text('Jugar');
    expect(play, findsOneWidget);

    await tester.ensureVisible(play);
    await tester.pumpAndSettle();
    await tester.tap(play);
    await tester.pumpAndSettle();

    // Sin dificultad guardada, Jugar debe abrir el selector.
    final dialog = tester.widget<Dialog>(
      find.byKey(const Key('difficulty-dialog')),
    );

    expect(dialog.backgroundColor, AppColors.white);
    expect(find.text('Selecciona la dificultad'), findsOneWidget);
    expect(find.byKey(const Key('difficulty-option-3')), findsOneWidget);
    expect(find.byKey(const Key('difficulty-option-4')), findsOneWidget);
    expect(find.byKey(const Key('difficulty-option-5')), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('difficulty-dialog')), findsNothing);
    expect(find.text('Jugar'), findsOneWidget);
  });

  testWidgets('La victoria usa el mismo diálogo de marca en tema oscuro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: PuzzleGameScreen(
          gridSize: 3,
          tileStyle: TileStyle.classic,
          animationsEnabled: false,
          storage: LocalStorage(),
          initialEngine: PuzzleEngine(
            gridSize: 3,
            initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(
      find.byKey(const Key('victory-dialog')),
    );

    expect(dialog.backgroundColor, AppColors.white);
    expect(find.text('¡Rompecabezas resuelto!'), findsOneWidget);
    expect(find.textContaining('Movimientos: 1'), findsOneWidget);
    expect(find.byKey(const Key('victory-reset-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('victory-reset-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('victory-dialog')), findsNothing);
  });
}
