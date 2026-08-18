import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lankapos/main.dart';
import 'package:lankapos/views/business_setup_view.dart';

void main() {
  testWidgets('Business setup screen rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with the onboarding view as initial home.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(initialHome: BusinessSetupView()),
      ),
    );

    // Verify that our app header and title are present.
    expect(find.text('LankaPOS'), findsOneWidget);
    expect(find.text('Setup Your Business Profile'), findsOneWidget);

    // Verify that the four business types are listed.
    expect(find.text('Grocery & Retail'), findsOneWidget);
    expect(find.text('Cafe & Bakery'), findsOneWidget);
    expect(find.text('Restaurant & Hotel'), findsOneWidget);
    expect(find.text('Service & Other'), findsOneWidget);

    // Verify shop details labels are visible.
    expect(find.text('SHOP NAME'), findsOneWidget);
    expect(find.text('CITY / ADDRESS'), findsOneWidget);
    expect(find.text('PHONE NUMBER'), findsOneWidget);
  });
}
