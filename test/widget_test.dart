
import 'package:flutter_test/flutter_test.dart';
import 'package:speeDGA/main.dart';

void main() {
  testWidgets('speeDGA initial state and tracking toggle', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpeeDGAApp());

    // Verify the initial state of the UI.
    // Speedometer shows 0.
    expect(find.text('0'), findsWidgets); 
    // Control button shows "INICIAR speeDGA".
    expect(find.text('INICIAR speeDGA'), findsOneWidget);
    expect(find.text('DETENER TRAYECTO'), findsNothing);

    // Tap the "INICIAR speeDGA" button to start tracking.
    await tester.tap(find.text('INICIAR speeDGA'));
    await tester.pump();

    // Verify that the button text changes to "DETENER TRAYECTO".
    expect(find.text('INICIAR speeDGA'), findsNothing);
    expect(find.text('DETENER TRAYECTO'), findsOneWidget);
  });
}
