import 'package:dating_app/core/theme/theme.dart';
import 'package:dating_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'controls support interaction and large text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = false;
        var presses = 0;
        final form = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StatefulBuilder(
                    builder: (context, setState) => Column(
                      children: [
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: () => presses++,
                        ),
                        const LoveButton(label: 'Disabled'),
                        const PrimaryButton(label: 'Working', isLoading: true),
                        SelectionChip(
                          label: 'Coffee',
                          selected: selected,
                          onSelected: (value) =>
                              setState(() => selected = value),
                        ),
                        SelectionCard(
                          title: 'Golden retriever',
                          subtitle: 'Outgoing, friendly',
                          selected: selected,
                          onTap: () => setState(() => selected = !selected),
                        ),
                        Form(
                          key: form,
                          child: AppTextField(
                            label: 'Name',
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const VibeBadge(percentage: 86),
                        const VibeChip(label: 'Night drives'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Continue'));
        expect(presses, 1);
        await tester.tap(find.text('Disabled'));
        expect(presses, 1);
        await tester.tap(find.text('Coffee'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(selected, isTrue);
        expect(
          tester.widget<FilterChip>(find.byType(FilterChip)).selected,
          isTrue,
        );
        expect(form.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Required'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
