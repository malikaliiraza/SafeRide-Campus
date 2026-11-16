import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_campus/main.dart';

void main() {
  testWidgets('home screen shows the app title and sample routes',
      (tester) async {
    await tester.pumpWidget(const SafeRideCampusApp());
    await tester.pump();

    expect(find.text('SafeRide Campus'), findsWidgets);
    expect(find.text('Parent safe-arrival alerts'), findsOneWidget);
    expect(find.text("Today's routes"), findsOneWidget);
    expect(find.text('Route A'), findsOneWidget);
    expect(find.text('Route B'), findsOneWidget);
    // Route C sits below the fold in the default test viewport.
    await tester.scrollUntilVisible(find.text('Route C'), 200);
    expect(find.text('Route C'), findsOneWidget);
  });
}
