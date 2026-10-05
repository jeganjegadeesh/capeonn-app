import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/core/network/api_exception.dart';
import 'package:capeonn_app/core/theme/app_theme.dart';
import 'package:capeonn_app/core/widgets/app_toast.dart';

void main() {
  Widget createTestWidget({required void Function(BuildContext context) onTrigger}) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => onTrigger(context),
              child: const Text('Trigger Toast'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('AppToast.success displays floating toast with clean message', (tester) async {
    await tester.pumpWidget(createTestWidget(
      onTrigger: (context) => AppToast.success(context, 'Task completed successfully!'),
    ));

    await tester.tap(find.text('Trigger Toast'));
    await tester.pumpAndSettle();

    expect(find.text('Task completed successfully!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
  });

  testWidgets('AppToast.error cleans Unhandled Exception and ApiException(422): words', (tester) async {
    await tester.pumpWidget(createTestWidget(
      onTrigger: (context) => AppToast.error(
        context,
        "Unhandled Exception: ApiException(422): Status transition from 'in_progress' to 'completed' is not permitted",
      ),
    ));

    await tester.tap(find.text('Trigger Toast'));
    await tester.pumpAndSettle();

    // Cleaned message must be present
    expect(find.text("Status transition from 'in_progress' to 'completed' is not permitted"), findsOneWidget);
    // Raw prefixes must NOT be present
    expect(find.textContaining('Unhandled Exception:'), findsNothing);
    expect(find.textContaining('ApiException(422):'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
  });

  testWidgets('AppToast.warning and info display floating cards', (tester) async {
    await tester.pumpWidget(createTestWidget(
      onTrigger: (context) {
        AppToast.warning(context, 'Warning note');
      },
    ));

    await tester.tap(find.text('Trigger Toast'));
    await tester.pumpAndSettle();

    expect(find.text('Warning note'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('AppToast dismiss button dismisses toast', (tester) async {
    await tester.pumpWidget(createTestWidget(
      onTrigger: (context) => AppToast.info(context, 'Dismissable message'),
    ));

    await tester.tap(find.text('Trigger Toast'));
    await tester.pumpAndSettle();

    expect(find.text('Dismissable message'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Dismissable message'), findsNothing);
  });
}
