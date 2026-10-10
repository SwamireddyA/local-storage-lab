
import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_lab/database_helper.dart';
import 'package:local_storage_lab/main.dart';

void main() {
  testWidgets('Fall Festival Roster app loads',
      (WidgetTester tester) async {
    final helper = DatabaseHelper();
    await helper.init();

    await tester.pumpWidget(DirectoryApp(helper: helper));
    await tester.pumpAndSettle();

    expect(find.text('Fall Festival Roster'), findsOneWidget);
    expect(find.text('Guest name'), findsOneWidget);
    expect(find.text('Age (0-130)'), findsOneWidget);
  });
}
