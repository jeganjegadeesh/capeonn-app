import 'package:capeonn_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mobile Viewport Overflow Audit Tests', () {
    testWidgets('Dialogs with ConstrainedBox fit within 320x568 mobile viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Track any FlutterError (e.g. RenderFlex overflow)
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.description, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Generate Very Long Report Title That Could Overflow',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          content: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Select options for this report:'),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: 'all',
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('All Departments In Company')),
                                    ],
                                    onChanged: (_) {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () {}, child: const Text('Cancel')),
                            ElevatedButton(onPressed: () {}, child: const Text('Export CSV')),
                          ],
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Assert dialog is rendered without any RenderFlex overflow errors
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
      final hasOverflowErrors = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflowErrors, isFalse, reason: 'RenderFlex overflow occurred on 320x568 viewport');
    });

    testWidgets('Header Row with Expanded text never overflows on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Very Long Header Title Directory Of All Personnel In Workspace',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add Employee'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Add Employee'), findsOneWidget);
      final hasOverflowErrors = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflowErrors, isFalse);
    });

    testWidgets('Scrollable TabBar renders 5 tabs cleanly without overflow on 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const DefaultTabController(
            length: 5,
            child: Scaffold(
              body: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Subtasks (12)'),
                      Tab(text: 'Time Logs (8)'),
                      Tab(text: 'Comments (15)'),
                      Tab(text: 'Attachments (4)'),
                      Tab(text: 'Activity (25)'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Center(child: Text('Tab 1')),
                        Center(child: Text('Tab 2')),
                        Center(child: Text('Tab 3')),
                        Center(child: Text('Tab 4')),
                        Center(child: Text('Tab 5')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Subtasks (12)'), findsOneWidget);
      final hasOverflowErrors = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflowErrors, isFalse);
    });

    testWidgets('Adaptive layout stacks on mobile viewports without horizontal clipping', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 440;
                  final searchField = const TextField(
                    decoration: InputDecoration(hintText: 'Search files...'),
                  );
                  final uploadButton = ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload File'),
                    onPressed: () {},
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        uploadButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 12),
                      uploadButton,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Upload File'), findsOneWidget);
      final hasOverflowErrors = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflowErrors, isFalse);
    });
  });
}
