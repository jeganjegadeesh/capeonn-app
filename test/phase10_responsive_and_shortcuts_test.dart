import 'package:capeonn_app/core/responsive/responsive_layout.dart';
import 'package:capeonn_app/core/shortcuts/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 10 — Responsive Layout & Breakpoints Tests', () {
    test('verifies standard 4-tier breakpoint thresholds', () {
      expect(Breakpoints.mobileMax, 599.0);
      expect(Breakpoints.tabletMin, 600.0);
      expect(Breakpoints.tabletMax, 1023.0);
      expect(Breakpoints.desktopMin, 1024.0);
      expect(Breakpoints.wideDesktopMin, 1440.0);
      expect(Breakpoints.maxContentWidth, 1400.0);
    });

    testWidgets('evaluates mobile viewport correctly (<600px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;
      late bool isCompact;
      late String responsiveVal;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = context.isMobile;
              isTablet = context.isTablet;
              isDesktop = context.isDesktop;
              isCompact = context.isCompact;
              responsiveVal = context.responsive<String>(
                mobile: 'mob',
                tablet: 'tab',
                desktop: 'desk',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMobile, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
      expect(isCompact, isTrue);
      expect(responsiveVal, 'mob');
    });

    testWidgets('evaluates tablet viewport correctly (600px - 1023px)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;
      late String responsiveVal;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = context.isMobile;
              isTablet = context.isTablet;
              isDesktop = context.isDesktop;
              responsiveVal = context.responsive<String>(
                mobile: 'mob',
                tablet: 'tab',
                desktop: 'desk',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMobile, isFalse);
      expect(isTablet, isTrue);
      expect(isDesktop, isFalse);
      expect(responsiveVal, 'tab');
    });

    testWidgets('evaluates desktop and wide desktop viewports correctly', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late bool isDesktop;
      late bool isWideDesktop;
      late bool isCompact;
      late String responsiveVal;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isDesktop = context.isDesktop;
              isWideDesktop = context.isWideDesktop;
              isCompact = context.isCompact;
              responsiveVal = context.responsive<String>(
                mobile: 'mob',
                tablet: 'tab',
                desktop: 'desk',
                wideDesktop: 'wide',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isDesktop, isTrue);
      expect(isWideDesktop, isTrue);
      expect(isCompact, isFalse);
      expect(responsiveVal, 'wide');
    });

    testWidgets('ResponsiveContentContainer constrains child width on 4K display', (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContentContainer(
              child: SizedBox(
                key: Key('inner_box'),
                height: 100,
              ),
            ),
          ),
        ),
      );

      final boxFinder = find.byKey(const Key('inner_box'));
      expect(boxFinder, findsOneWidget);
      final size = tester.getSize(boxFinder);
      expect(size.width, lessThanOrEqualTo(Breakpoints.maxContentWidth));
    });
  });

  group('Phase 10 — Shortcuts Registry Tests', () {
    test('contains core platform navigation and action shortcuts', () {
      final keys = AppShortcuts.all.map((s) => s.keys).toList();

      expect(keys.any((k) => k.contains('Ctrl + K')), isTrue);
      expect(keys.any((k) => k.contains('Ctrl + N')), isTrue);
      expect(keys.any((k) => k.contains('Ctrl + /')), isTrue);
    });

    test('verifies intent instantiation', () {
      const openPalette = OpenCommandPaletteIntent();
      const createTask = CreateTaskIntent();
      const createProject = CreateProjectIntent();
      const refresh = RefreshPageIntent();
      const help = ShowShortcutsHelpIntent();
      const escape = EscapeIntent();

      expect(openPalette, isA<Intent>());
      expect(createTask, isA<Intent>());
      expect(createProject, isA<Intent>());
      expect(refresh, isA<Intent>());
      expect(help, isA<Intent>());
      expect(escape, isA<Intent>());
    });
  });
}
