import 'package:orphan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/widgets/sponsors_pyramid_hierarchy.dart';

void main() {
  testWidgets('SponsorsPyramidHierarchy renders properly with all levels', (
    WidgetTester tester,
  ) async {
    final institutions = [
      const SponsorStatItem(
        id: 'inst-1',
        name: 'مؤسسة الأمل الخيرية',
        category: 'institution',
        sponsoredCount: 15,
        candidateCount: 4,
      ),
      const SponsorStatItem(
        id: 'inst-2',
        name: 'جمعية الإحسان',
        category: 'institution',
        sponsoredCount: 8,
        candidateCount: 2,
      ),
    ];

    final individuals = [
      const SponsorStatItem(
        id: 'indiv-1',
        name: 'أحمد محمد',
        category: 'individual',
        sponsoredCount: 2,
        candidateCount: 1,
      ),
      const SponsorStatItem(
        id: 'indiv-2',
        name: 'فاطمة محمود',
        category: 'individual',
        sponsoredCount: 3,
        candidateCount: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SponsorsPyramidHierarchy(
              totalSponsoredCount: 28,
              totalCandidatesCount: 7,
              institutionsSponsoredCount: 23,
              institutionsCandidatesCount: 6,
              individualsSponsoredCount: 5,
              individualsCandidatesCount: 1,
              institutions: institutions,
              individuals: individuals,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Level 1: Apex "الكفلاء"
    expect(find.text('الكفلاء'), findsOneWidget);
    expect(find.text('28'), findsOneWidget); // total sponsored
    expect(find.text('7'), findsOneWidget); // total candidates

    // Verify Level 2: Branches "مؤسسات" and "أفراد"
    expect(find.text('مؤسسات'), findsOneWidget);
    expect(find.text('23'), findsOneWidget); // institutions sponsored
    expect(find.text('6'), findsOneWidget); // institutions candidates

    expect(find.text('أفراد'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // individuals sponsored
    expect(find.text('1'), findsNWidgets(2)); // individual branch (1) and indiv-1 candidate (1)

    // Verify Level 3: Individual institutions and individuals
    expect(find.text('مؤسسة الأمل الخيرية'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    expect(find.text('جمعية الإحسان'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2)); // inst-2 candidate (2) and indiv-1 sponsored (2)

    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('فاطمة محمود'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
