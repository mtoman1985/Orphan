import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:orphan/pages/registration/registration_form_i18n.dart';
import '../../models/child.dart';
import '../../models/document.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';
import '../../models/country.dart';
import 'registration_form_logic.dart';
import '../utilities/add_payment_dialog.dart';
import 'package:uuid/uuid.dart';
import '../../models/sponsor.dart';
import '../../services/multilang_transliterator.dart';
import '../../widgets/universal_image.dart';
import 'package:printing/printing.dart';

class RegistrationForm extends StatefulWidget {
  final Child? child;

  const RegistrationForm({super.key, this.child});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm>
    with RegistrationFormLogic {
  @override
  void initState() {
    super.initState();
    initializeForm();
  }

  @override
  void dispose() {
    disposeRegistrationFormLogic();
    super.dispose();
  }

  /// تحديد اتجاه النص بناءً على اللغة الحالية
  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  /// الحصول على اتجاه النص
  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// الحصول على اسم المدينة حسب لغة التطبيق
  String _getCityName(Map<String, dynamic> city) {
    final langCode = Localizations.localeOf(context).languageCode;
    switch (langCode) {
      case 'en':
        return city['name_en'] ?? city['name_ar'];
      case 'tr':
        return city['name_tr'] ?? city['name_ar'];
      default:
        return city['name_ar'];
    }
  }

  /// الحصول على اسم الدولة حسب لغة التطبيق
  String _getCountryName(Country country) {
    final langCode = Localizations.localeOf(context).languageCode;
    return country.getName(langCode);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasOngoingSponsor = sponsors.any((s) => s.isOngoing);
    final steps = [
      loc.get('step_1_basic_family').replaceAll(RegExp(r'^\d+\.\s*'), ''),
      loc.get('step_2_education_health').replaceAll(RegExp(r'^\d+\.\s*'), ''),
      loc.get('step_3_documents').replaceAll(RegExp(r'^\d+\.\s*'), ''),
      loc.get('step_4_sponsorship').replaceAll(RegExp(r'^\d+\.\s*'), ''),
      if (hasOngoingSponsor)
        loc.get('step_5_payments').replaceAll(RegExp(r'^\d+\.\s*'), ''),
      loc.get('step_6_reporting').replaceAll(RegExp(r'^\d+\.\s*'), ''),
    ];

    // Ensure currentStep is within bounds if steps list shrinks
    if (currentStep >= steps.length) {
      currentStep = steps.length - 1;
    }

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              AppLocalizations.of(context).get('create_child_profile'),
            ),
          ),
          actions: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 100),
              child: IconButton(
                icon: Icon(showSidebar ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => showSidebar = !showSidebar),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                textDirection: _textDirection,
                children: [
                  if (showSidebar)
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      child: SizedBox(width: 260, child: _buildStepList(steps)),
                    ),
                  if (showSidebar) const SizedBox(width: 18),
                  Expanded(
                    child: SlideInRight(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 100),
                      child: _buildContentCard(steps, hasOngoingSponsor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepList(List<String> steps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: steps.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: _buildStepItem(steps, index)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepItem(List<String> steps, int index) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;
    return InkWell(
      onTap: () => setState(() => currentStep = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : isCompleted
                  ? Colors.green.shade50
                  : Colors.transparent,
          border: Border(
            left:
                _isArabic
                    ? BorderSide.none
                    : BorderSide(
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : isCompleted
                              ? Colors.green
                              : Colors.transparent,
                      width: 4,
                    ),
            right:
                _isArabic
                    ? BorderSide(
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : isCompleted
                              ? Colors.green
                              : Colors.transparent,
                      width: 4,
                    )
                    : BorderSide.none,
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          textDirection: _textDirection,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                        ? Colors.green
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow:
                    isActive
                        ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                steps[index],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color:
                      isActive
                          ? Theme.of(context).colorScheme.primary
                          : isCompleted
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(List<String> steps, bool hasOngoingSponsor) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).get('create_child_profile'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (currentStep != steps.length - 1) ...[
                        const SizedBox(height: 12),
                        Text(
                          steps[currentStep],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  FadeInRight(
                    duration: const Duration(milliseconds: 600),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (currentStep + 1) / steps.length,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${(((currentStep + 1) / steps.length) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 100),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 200),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: _buildCurrentStepContent(hasOngoingSponsor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Navigation
            Row(
              children: [
                if (currentStep > 0)
                  _buildActionButton(
                    label: loc.get('btn_back'),
                    icon: Icons.arrow_back,
                    onPressed: () => setState(() => currentStep--),
                    variant: 'outlined',
                  )
                else
                  const SizedBox(width: 40),
                const Spacer(),
                // زر الحفظ بجانب زر المتابعة
                _buildActionButton(
                  label: loc.get('save'),
                  icon: Icons.save_outlined,
                  onPressed: () => submit(),
                  variant: 'outlined',
                ),
                const SizedBox(width: 12),
                if (currentStep < steps.length - 1)
                  _buildActionButton(
                    label: loc.get('btn_continue'),
                    icon: Icons.arrow_forward,
                    onPressed: () async {
                      if (await validateCurrentStepAsync()) {
                        setState(() => currentStep++);
                      }
                    },
                    variant: 'filled',
                  )
                else
                  _buildActionButton(
                    label: loc.get('btn_finish'),
                    icon: Icons.check_circle,
                    onPressed: () => finishAndClose(),
                    variant: 'filled',
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required String variant,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    if (variant == 'filled') {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      );
    } else if (variant == 'outlined') {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(
            color: buttonColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
  }

  Widget _buildCurrentStepContent(bool hasOngoingSponsor) {
    // Correct mapping for logical steps
    final logicalSteps = [
      _buildBasicAndFamilyInfoStep(),
      _buildEducationHealthStep(),
      _buildDocumentUploadsStep(),
      _buildSponsorshipStep(),
      if (hasOngoingSponsor) _buildPaymentsStep(),
      _buildReportingStep(),
    ];

    if (currentStep >= logicalSteps.length) {
      return const Center(child: Text('Step not found'));
    }

    return logicalSteps[currentStep];
  }

  Widget _buildBasicAndFamilyInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child Personal Information
          _buildSectionTitle(
            AppLocalizations.of(context).get('child_personal_info'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Four Names: First Name, Father Name, Grandfather Name, Family Name
                  Row(
                    children: [
                      // الاسم الأول
                      Expanded(
                        child: TextFormField(
                          controller: firstNameCtl,
                          focusNode: firstNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('first_name'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                            helperText:
                                (_isArabic &&
                                        transliteratedFirstNameEn.isNotEmpty)
                                    ? 'English: $transliteratedFirstNameEn | Turkish: $transliteratedFirstNameTr'
                                    : null,
                            helperStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, fatherNameFocus),
                          validator:
                              (val) =>
                                  val?.trim().isEmpty == true
                                      ? AppLocalizations.of(
                                        context,
                                      ).get('required_field')
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // الاسم الثاني (الأب)
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: fatherNameCtl,
                          builder: (context, value, child) {
                            final name = value.text.trim();
                            final englishName =
                                name.isEmpty
                                    ? ''
                                    : MultiLangTransliterator.toEnglish(name);
                            final turkishName =
                                name.isEmpty
                                    ? ''
                                    : MultiLangTransliterator.toTurkish(name);

                            return TextFormField(
                              controller: fatherNameCtl,
                              focusNode: fatherNameFocus,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                ).get('second_name'),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.person_outline),
                                helperText:
                                    (_isArabic && englishName.isNotEmpty)
                                        ? 'English: $englishName | Turkish: $turkishName'
                                        : null,
                                helperStyle: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted:
                                  (_) => focusNextField(
                                    context,
                                    grandfatherNameFocus,
                                  ),
                              validator:
                                  (val) =>
                                      val?.trim().isEmpty == true
                                          ? AppLocalizations.of(
                                            context,
                                          ).get('required_field')
                                          : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // الاسم الثالث (الجد)
                      Expanded(
                        child: TextFormField(
                          controller: grandfatherNameCtl,
                          focusNode: grandfatherNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('third_name'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person_outline),
                            helperText:
                                (_isArabic &&
                                        transliteratedGrandfatherNameEn
                                            .isNotEmpty)
                                    ? 'English: $transliteratedGrandfatherNameEn | Turkish: $transliteratedGrandfatherNameTr'
                                    : null,
                            helperStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, familyNameFocus),
                          validator:
                              (val) =>
                                  val?.trim().isEmpty == true
                                      ? AppLocalizations.of(
                                        context,
                                      ).get('required_field')
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // اسم العائلة
                      Expanded(
                        child: TextFormField(
                          controller: familyNameCtl,
                          focusNode: familyNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('family_name'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.family_restroom),
                            helperText:
                                (_isArabic &&
                                        transliteratedLastNameEn.isNotEmpty)
                                    ? 'English: $transliteratedLastNameEn | Turkish: $transliteratedLastNameTr'
                                    : null,
                            helperStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, nationalIdFocus),
                          validator:
                              (val) =>
                                  val?.trim().isEmpty == true
                                      ? AppLocalizations.of(
                                        context,
                                      ).get('required_field')
                                      : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Gender, Birth Date, Age, Child ID Code, National ID
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: (gender == 'M' || gender == 'F') ? gender : null,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.get('gender'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wc),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'M',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.get('gender_male'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.get('gender_female'),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() => gender = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: birthDateCtl,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('birth_date'),
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null)
                                  setState(() {
                                    birthDateCtl.text =
                                        date.toIso8601String().split('T')[0];
                                    dateOfBirth = date;
                                    // حساب المستوى التعليمي تلقائياً من تاريخ الميلاد
                                    educationLevel =
                                        calculateEducationLevelFromAge(date);
                                  });
                              },
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.blue.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).get('age'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_calculateAge(birthDateCtl.text)} ${AppLocalizations.of(context).get('years')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: childIdCtl,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('child_id_code'),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: nationalIdCtl,
                          focusNode: nationalIdFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('national_id'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                            hintText: AppLocalizations.of(
                              context,
                            ).get('numbers_only'),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade600,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, streetFocus),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                                return AppLocalizations.of(
                                  context,
                                ).get('numbers_only');
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Place of Birth Section
          _buildSectionTitle(
            AppLocalizations.of(context).get('birth_place_info'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<Country>(
                      value:
                          selectedBirthCountry != null &&
                                  countries.any(
                                    (c) => c.id == selectedBirthCountry!.id,
                                  )
                              ? countries.firstWhere(
                                (c) => c.id == selectedBirthCountry!.id,
                              )
                              : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).get('birth_country'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.public),
                      ),
                      isExpanded: true,
                      items: [
                        ...countries.map(
                          (country) => DropdownMenuItem<Country>(
                            value: country,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getCountryName(country),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Future.delayed(
                                        const Duration(milliseconds: 150),
                                        () => showEditCountryDialog(country),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const DropdownMenuItem<Country>(
                          enabled: false,
                          value: null,
                          child: Divider(),
                        ),
                        DropdownMenuItem<Country>(
                          enabled: false,
                          value: null,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Future.delayed(
                                const Duration(milliseconds: 150),
                                showAddCountryDialog,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).get('add_new_country'),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: handleBirthCountryChange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value:
                          selectedBirthCity != null &&
                                  birthCities.any(
                                    (c) => c['name_ar'] == selectedBirthCity,
                                  )
                              ? selectedBirthCity
                              : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).get('birth_city'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                      isExpanded: true,
                      items: [
                        ...(() {
                          final seen = <String>{};
                          return birthCities
                              .where(
                                (city) => seen.add(city['name_ar'] as String),
                              )
                              .map(
                                (city) => DropdownMenuItem<String>(
                                  value: city['name_ar'],
                                  child: Text(_getCityName(city)),
                                ),
                              )
                              .toList();
                        })(),
                        if (birthCities.isNotEmpty)
                          const DropdownMenuItem<String>(
                            enabled: false,
                            value: null,
                            child: Divider(),
                          ),
                        if (selectedBirthCountry != null)
                          DropdownMenuItem<String>(
                            enabled: false,
                            value: null,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Future.delayed(
                                  const Duration(milliseconds: 150),
                                  showAddBirthCityDialog,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).get('add_new_city'),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBirthCity = newValue;
                          birthCityCtl.text = newValue ?? '';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Residence Information Section (السكن)
          _buildSectionTitle(
            AppLocalizations.of(context).get('residence_info'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<Country>(
                      value:
                          selectedCountry != null &&
                                  countries.any(
                                    (c) => c.id == selectedCountry!.id,
                                  )
                              ? countries.firstWhere(
                                (c) => c.id == selectedCountry!.id,
                              )
                              : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('country'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.public),
                      ),
                      isExpanded: true,
                      items: [
                        ...countries.map(
                          (country) => DropdownMenuItem<Country>(
                            value: country,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getCountryName(country),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Future.delayed(
                                        const Duration(milliseconds: 150),
                                        () => showEditCountryDialog(country),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const DropdownMenuItem<Country>(
                          enabled: false,
                          value: null,
                          child: Divider(),
                        ),
                        DropdownMenuItem<Country>(
                          enabled: false,
                          value: null,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Future.delayed(
                                const Duration(milliseconds: 150),
                                showAddCountryDialog,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).get('add_new_country'),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      validator:
                          (value) =>
                              value == null
                                  ? AppLocalizations.of(
                                    context,
                                  ).get('required_field')
                                  : null,
                      onChanged: handleCountryChange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value:
                          selectedCity != null &&
                                  cities.any(
                                    (c) => c['name_ar'] == selectedCity,
                                  )
                              ? selectedCity
                              : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('city'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                      isExpanded: true,
                      items: [
                        ...(() {
                          final seen = <String>{};
                          return cities
                              .where(
                                (city) => seen.add(city['name_ar'] as String),
                              )
                              .map(
                                (city) => DropdownMenuItem<String>(
                                  value: city['name_ar'],
                                  child: Text(_getCityName(city)),
                                ),
                              )
                              .toList();
                        })(),
                        if (cities.isNotEmpty)
                          const DropdownMenuItem<String>(
                            enabled: false,
                            value: null,
                            child: Divider(),
                          ),
                        if (selectedCountry != null)
                          DropdownMenuItem<String>(
                            enabled: false,
                            value: null,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Future.delayed(
                                  const Duration(milliseconds: 150),
                                  showAddCityDialog,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).get('add_new_city'),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue;
                          cityCtl.text = newValue ?? '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: streetCtl,
                      focusNode: streetFocus,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('street'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted:
                          (_) => focusNextField(context, fatherNameFocus),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Parents Information
          _buildSectionTitle(
            AppLocalizations.of(context).get('parents_information'),
          ),
          const SizedBox(height: 16),

          // Father Information Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Father Information Section Header
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.male, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).get('father_information'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 1: Father Name, Father ID, Father Status
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: fatherFullNameCtl,
                          focusNode: fatherNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('father_full_name'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            helperText: AppLocalizations.of(
                              context,
                            ).get('auto_calculated_father_hint'),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          readOnly: true,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, fatherIdFocus),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: fatherIdCtl,
                          focusNode: fatherIdFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('father_id'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                            hintText: AppLocalizations.of(
                              context,
                            ).get('numbers_only'),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade600,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, motherNameFocus),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                                return 'Numbers only';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: fatherStatus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('father_status'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Alive',
                              child: Text(
                                AppLocalizations.of(context).get('alive'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Deceased',
                              child: Text(
                                AppLocalizations.of(context).get('deceased'),
                              ),
                            ),
                          ],
                          onChanged:
                              (val) => setState(() => fatherStatus = val!),
                        ),
                      ),
                    ],
                  ),

                  // Death Info Fields for Father (if Deceased)
                  if (fatherStatus == 'Deceased') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: fatherDeathDateCtl,
                            focusNode: fatherDeathDateFocus,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).get('death_date'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  fatherDeathDateCtl.text =
                                      date.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value:
                                [
                                      'Disease',
                                      'War',
                                      'Natural Death',
                                      'Accident',
                                    ].contains(fatherDeathCause)
                                    ? fatherDeathCause
                                    : (fatherDeathCause != null
                                        ? 'Other'
                                        : null),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).get('death_cause'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Disease',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_disease'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'War',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_war'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Natural Death',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_natural'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Accident',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_accident'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_other'),
                                ),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val == 'Other') {
                                await _showCustomCauseDialog(true);
                              } else {
                                setState(() => fatherDeathCause = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (fatherDeathCause != null &&
                        ![
                          'Disease',
                          'War',
                          'Natural Death',
                          'Accident',
                        ].contains(fatherDeathCause))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${AppLocalizations.of(context).get('death_cause')}: $fatherDeathCause',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mother Information Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mother Information Section Header
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      border: Border.all(color: Colors.pink.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.female, color: Colors.pink.shade900),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).get('mother_information'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.pink.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Mother Name, Mother ID, Mother Status
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: motherFullNameCtl,
                          focusNode: motherNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('mother_full_name'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, motherIdFocus),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: motherIdCtl,
                          focusNode: motherIdFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('mother_id'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                            hintText: AppLocalizations.of(
                              context,
                            ).get('numbers_only'),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade600,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) => focusNextField(context, guardianNameFocus),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                                return 'Numbers only';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: motherStatus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('mother_status'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Alive',
                              child: Text(
                                AppLocalizations.of(context).get('alive'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Deceased',
                              child: Text(
                                AppLocalizations.of(context).get('deceased'),
                              ),
                            ),
                          ],
                          onChanged:
                              (val) => setState(() => motherStatus = val!),
                        ),
                      ),
                    ],
                  ),

                  // Death Info Fields for Mother (if Deceased)
                  if (motherStatus == 'Deceased') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: motherDeathDateCtl,
                            focusNode: motherDeathDateFocus,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).get('death_date'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  motherDeathDateCtl.text =
                                      date.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value:
                                [
                                      'Disease',
                                      'War',
                                      'Natural Death',
                                      'Accident',
                                    ].contains(motherDeathCause)
                                    ? motherDeathCause
                                    : (motherDeathCause != null
                                        ? 'Other'
                                        : null),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).get('death_cause'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Disease',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_disease'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'War',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_war'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Natural Death',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_natural'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Accident',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_accident'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).get('death_cause_other'),
                                ),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val == 'Other') {
                                await _showCustomCauseDialog(false);
                              } else {
                                setState(() => motherDeathCause = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (motherDeathCause != null &&
                        ![
                          'Disease',
                          'War',
                          'Natural Death',
                          'Accident',
                        ].contains(motherDeathCause))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${AppLocalizations.of(context).get('death_cause')}: $motherDeathCause',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Guardian Information
          _buildSectionTitle(
            AppLocalizations.of(context).get('guardian_information'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Relationship, Guardian Name, Guardian Phone
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: [
                            'Mother',
                            'Father',
                            'Uncle',
                            'Aunt',
                            'Grandmother',
                            'Grandfather',
                            'Brother',
                            'Sister',
                            'Other',
                          ].contains(guardianRelationship)
                              ? guardianRelationship
                              : (guardianRelationship == 'الأم' || guardianRelationship == 'أم'
                                  ? 'Mother'
                                  : (guardianRelationship == 'الأب' || guardianRelationship == 'أب'
                                      ? 'Father'
                                      : (guardianRelationship != null && guardianRelationship!.isNotEmpty
                                          ? 'Other'
                                          : null))),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('relationship'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.family_restroom),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Mother',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_mother'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Father',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_father'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Uncle',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_uncle'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Aunt',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_aunt'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Grandmother',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_grandmother'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Grandfather',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_grandfather'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Brother',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_brother'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Sister',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_sister'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('relationship_other'),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              guardianRelationship = val!;
                              if (val == 'Mother') {
                                // Auto-fill guardian name with mother's name
                                if (motherFullNameCtl.text.isNotEmpty) {
                                  guardianNameCtl.text = motherFullNameCtl.text;
                                }
                                // Auto-fill guardian address with orphan's address
                                if (addressCtl.text.isNotEmpty) {
                                  guardianAddressCtl.text = addressCtl.text;
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: guardianNameCtl,
                          focusNode: guardianNameFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('guardian_name'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) =>
                                  focusNextField(context, guardianPhoneFocus),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: guardianPhoneCtl,
                          focusNode: guardianPhoneFocus,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).get('guardian_phone'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            hintText: AppLocalizations.of(
                              context,
                            ).get('numbers_only'),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade600,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted:
                              (_) =>
                                  focusNextField(context, guardianAddressFocus),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
                                return AppLocalizations.of(
                                  context,
                                ).get('numbers_only');
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Guardian Address
                  TextFormField(
                    controller: guardianAddressCtl,
                    focusNode: guardianAddressFocus,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).get('guardian_address'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Siblings Information
          _buildSectionTitle(
            AppLocalizations.of(context).get('siblings_information'),
          ),
          const SizedBox(height: 16),

          // Siblings List
          if (siblingsList.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).get('added_siblings')} (${siblingsList.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () async {
                          int registeredCount = 0;
                          final skippedNames = <String>[];
                          for (final sibling in siblingsList) {
                            final alreadyRegistered =
                                sibling['childProfileId']
                                    ?.toString()
                                    .isNotEmpty ??
                                false;
                            if (alreadyRegistered) continue;

                            final sibId = sibling['id']?.toString().trim() ?? '';
                            final sibName = sibling['name']?.toString().trim() ?? '';
                            if (sibId.isEmpty) {
                              skippedNames.add('$sibName (بدون رقم هوية)');
                              continue;
                            }
                            if (sibId == nationalIdCtl.text.trim()) {
                              skippedNames.add('$sibName (مطابق لرقم هوية اليتيم)');
                              continue;
                            }
                            final conflict = await checkSiblingNationalIdConflict(
                              sibId,
                              currentChildId: widget.child?.id,
                            );
                            if (conflict != null) {
                              skippedNames.add('$sibName (الهوية مسجلة لـ $conflict)');
                              continue;
                            }

                            sibling['registerAsChild'] = true;
                            sibling['gender'] ??= gender ?? 'M';
                            registeredCount++;
                          }
                          setState(() {});
                          if (skippedNames.isNotEmpty && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم تحديد $registeredCount أخ/أخت للتسجيل. تم استبعاد:\n${skippedNames.join('\n')}',
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.group_add),
                        label: Text(
                          AppLocalizations.of(
                            context,
                          ).get('register_all_siblings'),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.blue.shade100),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.blue.shade50,
                          ),
                          headingRowHeight: 56,
                          dataRowHeight: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('number_hash_label'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('sibling_name'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(context).get('sibling_id'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('sibling_profile_number'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('sibling_birth_date'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(context).get('sibling_age'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('sibling_status'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('register_sibling_as_child'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                ).get('sibling_action'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                          rows:
                              siblingsList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final sibling = entry.value;
                                final sponsorshipStatus =
                                    siblingSponsorshipStatus(sibling);
                                final sponsorshipColor =
                                    switch (sponsorshipStatus) {
                                      'sponsored' => Colors.green,
                                      'candidate' => Colors.blue,
                                      _ => Colors.orange,
                                    };
                                final sponsorshipLabel =
                                    switch (sponsorshipStatus) {
                                      'sponsored' => AppLocalizations.of(
                                        context,
                                      ).get('sponsored'),
                                      'candidate' => AppLocalizations.of(
                                        context,
                                      ).get('sponsorship_candidate'),
                                      _ => AppLocalizations.of(
                                        context,
                                      ).get('not_sponsored'),
                                    };
                                final isRegistered =
                                    sibling['childProfileId']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false;
                                return DataRow(
                                  color: MaterialStateProperty.all(
                                    index.isEven
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        sibling['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        sibling['id'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        sibling['childIdNumber']?.toString() ??
                                            '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _formatDateToDDMMYYYY(
                                          sibling['birthDate'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          '${_calculateAge(sibling['birthDate'])} ${AppLocalizations.of(context).get('years')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sponsorshipColor.shade100,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: sponsorshipColor.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          sponsorshipLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: sponsorshipColor.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Checkbox(
                                        value:
                                            sibling['registerAsChild'] ==
                                                true ||
                                            isRegistered,
                                        onChanged:
                                            isRegistered
                                                ? null
                                                : (value) async {
                                                  if (value == true) {
                                                    final sibId =
                                                        sibling['id']
                                                            ?.toString()
                                                            .trim() ??
                                                        '';
                                                    if (sibId.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'يرجى إدخال رقم الهوية للأخ أولاً لتسجيله في البرنامج',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    if (sibId ==
                                                        nationalIdCtl.text
                                                            .trim()) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'رقم هوية الأخ مطابق لرقم هوية اليتيم الأساسي!',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    final conflict =
                                                        await checkSiblingNationalIdConflict(
                                                          sibId,
                                                          currentChildId:
                                                              widget.child?.id,
                                                          excludeSiblingChildProfileId:
                                                              sibling['childProfileId']
                                                                  ?.toString(),
                                                        );
                                                    if (conflict != null) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'رقم الهوية ($sibId) مسجل مسبقاً في النظام لليتيم: $conflict',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                            duration:
                                                                const Duration(
                                                                  seconds: 4,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                  }
                                                  setState(() {
                                                    sibling['registerAsChild'] =
                                                        value ?? false;
                                                    if (value == true) {
                                                      sibling['gender'] ??=
                                                          gender ?? 'M';
                                                    }
                                                  });
                                                },
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue.shade500,
                                            ),
                                            onPressed: () {
                                              editSibling(context, index);
                                            },
                                            tooltip: AppLocalizations.of(
                                              context,
                                            ).get('edit_sibling'),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade500,
                                            ),
                                            onPressed: () {
                                              setState(
                                                () => removeSibling(index),
                                              );
                                            },
                                            tooltip: AppLocalizations.of(
                                              context,
                                            ).get('delete_sibling'),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              addSibling(context);
            },
            icon: Icon(Icons.person_add),
            label: Text(AppLocalizations.of(context).get('add_sibling')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Financial / Payment Information Section
          _buildSectionTitle(
            AppLocalizations.of(context)!.get('financial_info'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment Method Selector (Bank or Wallet)
                  DropdownButtonFormField<String>(
                    value: (paymentMethod == 'wallet') ? 'wallet' : 'bank',
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.get('payment_method'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'bank',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.get('payment_method_bank'),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'wallet',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.get('payment_method_wallet'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          paymentMethod = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final localizations = AppLocalizations.of(context)!;
                      final firstField =
                          paymentMethod == 'bank'
                              ? TextFormField(
                                controller: bankNameCtl,
                                decoration: InputDecoration(
                                  labelText: localizations.get('bank_name'),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.account_balance),
                                ),
                              )
                              : TextFormField(
                                controller: walletHolderNameCtl,
                                decoration: InputDecoration(
                                  labelText: localizations.get(
                                    'wallet_holder_name',
                                  ),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              );
                      final secondField =
                          paymentMethod == 'bank'
                              ? TextFormField(
                                controller: bankAccountHolderNameCtl,
                                decoration: InputDecoration(
                                  labelText: localizations.get(
                                    'account_holder',
                                  ),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              )
                              : TextFormField(
                                controller: walletNumberCtl,
                                decoration: InputDecoration(
                                  labelText: localizations.get(
                                    'linked_mobile_number',
                                  ),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.phone_android),
                                ),
                                keyboardType: TextInputType.phone,
                              );
                      final thirdField = TextFormField(
                        controller: walletNumberCtl,
                        decoration: InputDecoration(
                          labelText: localizations.get('linked_mobile_number'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone_android),
                        ),
                        keyboardType: TextInputType.phone,
                      );
                      final fourthField = TextFormField(
                        controller: bankIbanCtl,
                        decoration: InputDecoration(
                          labelText: localizations.get('iban'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.credit_card),
                        ),
                      );

                      Widget fieldPair(Widget first, Widget second) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              first,
                              const SizedBox(height: 12),
                              second,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: first),
                            const SizedBox(width: 12),
                            Expanded(child: second),
                          ],
                        );
                      }

                      if (paymentMethod == 'bank') {
                        return Column(
                          children: [
                            fieldPair(firstField, secondField),
                            const SizedBox(height: 12),
                            fieldPair(thirdField, fourthField),
                          ],
                        );
                      }
                      return fieldPair(firstField, secondField);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationHealthStep() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Education Section
          _buildSectionTitle(loc.get('step_education_health')),
          const SizedBox(height: 16),

          // Row 1: Education Level (Dropdown)
          DropdownButtonFormField<String>(
            value: [
              'education_level_none',
              'education_level_primary',
              'education_level_middle',
              'education_level_secondary',
              'education_level_college',
              'education_level_university',
              'education_level_not_studying',
            ].contains(educationLevel)
                ? educationLevel
                : 'education_level_none',
            decoration: InputDecoration(
              labelText: loc.get('education_level_label'),
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
            items: [
              DropdownMenuItem(
                value: 'education_level_none',
                child: Text(loc.get('education_level_none')),
              ),
              DropdownMenuItem(
                value: 'education_level_primary',
                child: Text(loc.get('education_level_primary')),
              ),
              DropdownMenuItem(
                value: 'education_level_middle',
                child: Text(loc.get('education_level_middle')),
              ),
              DropdownMenuItem(
                value: 'education_level_secondary',
                child: Text(loc.get('education_level_secondary')),
              ),
              DropdownMenuItem(
                value: 'education_level_college',
                child: Text(loc.get('education_level_college')),
              ),
              DropdownMenuItem(
                value: 'education_level_university',
                child: Text(loc.get('education_level_university')),
              ),
              DropdownMenuItem(
                value: 'education_level_not_studying',
                child: Text(loc.get('education_level_not_studying')),
              ),
            ],
            onChanged: (val) {
              setState(() {
                educationLevel = val;
                // Clear secondary fields when education level changes
                schoolClass = null;
                universityNameCtl.clear();
                universityCollegeCtl.clear();
                collegeSpecializationCtl.clear();
                universityYear = null;
                universityYearCtl.clear();
              });
            },
          ),
          const SizedBox(height: 16),

          // Row 2: School Class Dropdown (for Primary, Middle, Secondary)
          if (educationLevel == 'education_level_primary' ||
              educationLevel == 'education_level_middle' ||
              educationLevel == 'education_level_secondary') ...[
            Builder(
              builder: (context) {
                final validClasses = [
                  if (educationLevel == 'education_level_primary') ...[
                    RegistrationFormI18n.primary1,
                    RegistrationFormI18n.primary2,
                    RegistrationFormI18n.primary3,
                    RegistrationFormI18n.primary4,
                    RegistrationFormI18n.primary5,
                    RegistrationFormI18n.primary6,
                  ] else if (educationLevel == 'education_level_middle') ...[
                    RegistrationFormI18n.middle7,
                    RegistrationFormI18n.middle8,
                    RegistrationFormI18n.middle9,
                  ] else if (educationLevel == 'education_level_secondary') ...[
                    RegistrationFormI18n.secondary10,
                    RegistrationFormI18n.secondary11,
                    RegistrationFormI18n.secondary12,
                  ],
                ];
                final effectiveClassValue = (schoolClass != null &&
                        schoolClass!.isNotEmpty &&
                        validClasses.contains(schoolClass))
                    ? schoolClass
                    : null;

                return DropdownButtonFormField<String>(
                  value: effectiveClassValue,
                  decoration: InputDecoration(
                    labelText: loc.get('school_class'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.class_),
                  ),
              items: [
                if (educationLevel == 'education_level_primary') ...[
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary1,
                    child: Text(loc.get('primary_1')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary2,
                    child: Text(loc.get('primary_2')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary3,
                    child: Text(loc.get('primary_3')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary4,
                    child: Text(loc.get('primary_4')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary5,
                    child: Text(loc.get('primary_5')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.primary6,
                    child: Text(loc.get('primary_6')),
                  ),
                ] else if (educationLevel == 'education_level_middle') ...[
                  DropdownMenuItem(
                    value: RegistrationFormI18n.middle7,
                    child: Text(loc.get('middle_7')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.middle8,
                    child: Text(loc.get('middle_8')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.middle9,
                    child: Text(loc.get('middle_9')),
                  ),
                ] else if (educationLevel == 'education_level_secondary') ...[
                  DropdownMenuItem(
                    value: RegistrationFormI18n.secondary10,
                    child: Text(loc.get('secondary_10')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.secondary11,
                    child: Text(loc.get('secondary_11')),
                  ),
                  DropdownMenuItem(
                    value: RegistrationFormI18n.secondary12,
                    child: Text(loc.get('secondary_12')),
                  ),
                ],
              ],
              onChanged: (val) => setState(() => schoolClass = val),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // University, college, and specialization (for University level)
          if (educationLevel == 'education_level_university') ...[
            TextFormField(
              controller: universityNameCtl,
              decoration: InputDecoration(
                labelText: loc.get('university_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: universityCollegeCtl,
              decoration: InputDecoration(
                labelText: loc.get('college_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: collegeSpecializationCtl,
              decoration: InputDecoration(
                labelText: loc.get('specialization_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          // College and specialization (for College level)
          if (educationLevel == 'education_level_college') ...[
            TextFormField(
              controller: universityCollegeCtl,
              decoration: InputDecoration(
                labelText: loc.get('college_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: collegeSpecializationCtl,
              decoration: InputDecoration(
                labelText: loc.get('specialization_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Health Section
          _buildSectionTitle(loc.get('health_section')),
          const SizedBox(height: 16),

          // Row 1: Health Status
          DropdownButtonFormField<String>(
            value: ['Healthy', 'Sick', 'Disabled'].contains(healthStatus)
                ? healthStatus
                : 'Healthy',
            decoration: InputDecoration(
              labelText: loc.get('health_status_label'),
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.health_and_safety),
            ),
            items: [
              DropdownMenuItem(
                value: 'Healthy',
                child: Text(loc.get('healthy')),
              ),
              DropdownMenuItem(value: 'Sick', child: Text(loc.get('sick'))),
              DropdownMenuItem(
                value: 'Disabled',
                child: Text(loc.get('disabled')),
              ),
            ],
            onChanged: (val) => setState(() => healthStatus = val!),
          ),
          const SizedBox(height: 16),

          // Row 2: Disability Type (Conditional)
          if (healthStatus == 'Disabled') ...[
            DropdownButtonFormField<String>(
              value: [
                'physical',
                'visual',
                'auditory',
                'mental',
                'speech',
              ].contains(disabilityType)
                  ? disabilityType
                  : null,
              decoration: InputDecoration(
                labelText: loc.get('disability_type_label'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.accessible),
              ),
              items: [
                DropdownMenuItem(
                  value: 'physical',
                  child: Text(loc.get('disability_type_physical')),
                ),
                DropdownMenuItem(
                  value: 'visual',
                  child: Text(loc.get('disability_type_visual')),
                ),
                DropdownMenuItem(
                  value: 'auditory',
                  child: Text(loc.get('disability_type_auditory')),
                ),
                DropdownMenuItem(
                  value: 'mental',
                  child: Text(loc.get('disability_type_mental')),
                ),
                DropdownMenuItem(
                  value: 'speech',
                  child: Text(loc.get('disability_type_speech')),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(loc.get('disability_type_other')),
                ),
              ],
              onChanged: (val) => setState(() => disabilityType = val),
            ),
            const SizedBox(height: 16),
          ],

          // Row 3: Disability/Notes
          TextFormField(
            controller: disabilityCtl,
            focusNode: disabilityFocus,
            decoration: InputDecoration(
              labelText: loc.get('disability_notes'),
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt),
              hintText: loc.get('disability_notes'),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadsStep() {
    final loc = AppLocalizations.of(context);
    final uploadedFiles = allUploadedDocuments;
    final profilePhotos =
        uploadedFiles.where((doc) => doc.type == 'Profile').toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final birthCertificates =
        uploadedFiles.where((doc) => doc.type == 'BirthCertificate').toList();
    final motherIdPhotos =
        uploadedFiles.where((doc) => doc.type == 'MotherID').toList();
    final fatherDeathCertificates =
        uploadedFiles
            .where((doc) => doc.type == 'FatherDeathCertificate')
            .toList();
    final guardianIdPhotos =
        uploadedFiles
            .where((doc) => doc.type == 'Guardian' || doc.type == 'Guardain')
            .toList();
    final guardianshipDeeds =
        uploadedFiles.where((doc) => doc.type == 'GuardianshipDeed').toList();
    final educationCertificates =
        uploadedFiles
            .where(
              (doc) =>
                  doc.type == 'EducationCertificate' ||
                  doc.type == 'Certificate',
            )
            .toList();
    final reports =
        uploadedFiles
            .where(
              (doc) =>
                  doc.type == 'MedicalReport' ||
                  doc.type == 'HealthReport' ||
                  doc.type == 'Medical',
            )
            .toList();
    final categorizedTypes = {
      'Profile',
      'BirthCertificate',
      'MotherID',
      'FatherDeathCertificate',
      'Guardian',
      'Guardain',
      'GuardianshipDeed',
      'EducationCertificate',
      'Certificate',
      'MedicalReport',
      'HealthReport',
      'Medical',
    };
    final otherFiles =
        uploadedFiles
            .where((doc) => !categorizedTypes.contains(doc.type))
            .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(loc.get('orphan_documents')),
          const SizedBox(height: 16),
          _buildAttachmentFolder(
            title: loc.get('folder_personal_photos'),
            documents: profilePhotos,
            onUpload:
                () => pickAndCropImage(isDocument: true, customType: 'Profile'),
            isPhotoFolder: true,
            latestProfilePhotoId:
                profilePhotos.isEmpty ? null : profilePhotos.first.id,
          ),
          _buildAttachmentFolder(
            title: loc.get('folder_birth_certificates'),
            documents: birthCertificates,
            onUpload: () => pickAttachmentFile(type: 'BirthCertificate'),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle(loc.get('attachment_family')),
          const SizedBox(height: 16),
          _buildAttachmentFolder(
            title: loc.get('mother_id_photo'),
            documents: motherIdPhotos,
            onUpload:
                () =>
                    pickAndCropImage(isDocument: true, customType: 'MotherID'),
            isPhotoFolder: true,
          ),
          _buildAttachmentFolder(
            title: loc.get('father_death_certificate'),
            documents: fatherDeathCertificates,
            onUpload: () => pickAttachmentFile(type: 'FatherDeathCertificate'),
          ),
          _buildAttachmentFolder(
            title: loc.get('folder_guardianship_deed'),
            documents: guardianshipDeeds,
            onUpload: () => pickAttachmentFile(type: 'GuardianshipDeed'),
          ),
          if (guardianRelationship != 'Mother' &&
              guardianRelationship != 'الأم')
            _buildAttachmentFolder(
              title: loc.get('guardian_id_photo'),
              documents: guardianIdPhotos,
              onUpload:
                  () => pickAndCropImage(
                    isDocument: true,
                    customType: 'Guardian',
                  ),
              isPhotoFolder: true,
            ),
          const SizedBox(height: 8),
          _buildSectionTitle(loc.get('other_attachments')),
          const SizedBox(height: 16),
          _buildAttachmentFolder(
            title: loc.get('attachment_education'),
            documents: educationCertificates,
            onUpload: () => pickAttachmentFile(type: 'EducationCertificate'),
          ),
          _buildAttachmentFolder(
            title: loc.get('attachment_medical'),
            documents: reports,
            onUpload: () => pickAttachmentFile(type: 'MedicalReport'),
          ),
          _buildAttachmentFolder(
            title: loc.get('attachment_other'),
            documents: otherFiles,
            onUpload: () => pickAttachmentFile(type: 'File'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentFolder({
    required String title,
    required List<Document> documents,
    required VoidCallback onUpload,
    String? latestProfilePhotoId,
    bool isPhotoFolder = false,
  }) {
    final loc = AppLocalizations.of(context);
    final sortedDocuments = List<Document>.from(documents)
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final imageDocuments =
        sortedDocuments
            .where(
              (doc) => RegExp(
                r'\.(jpe?g|png|gif|webp|bmp)$',
                caseSensitive: false,
              ).hasMatch(doc.fileName),
            )
            .toList();
    final otherDocuments =
        sortedDocuments.where((doc) => !imageDocuments.contains(doc)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.folder, color: Colors.amber),
        title: Text(title),
        subtitle: Text('${sortedDocuments.length}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPhotoFolder)
                  _buildPhotoUploadCard(
                    title: title,
                    color: Colors.blue,
                    onTap: onUpload,
                    hasUploaded: sortedDocuments.isNotEmpty,
                    showTitle: false,
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: onUpload,
                      icon: const Icon(Icons.upload_file),
                      label: Text(loc.get('upload_button')),
                    ),
                  ),
                if (sortedDocuments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(loc.get('no_documents_uploaded')),
                  )
                else ...[
                  if (imageDocuments.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            (constraints.maxWidth / 132)
                                .floor()
                                .clamp(1, 6)
                                .toInt();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 180,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: imageDocuments.length,
                          itemBuilder: (context, index) {
                            final doc = imageDocuments[index];
                            final date = doc.uploadedAt;
                            final formattedDate =
                                '${date.year}-'
                                '${date.month.toString().padLeft(2, '0')}-'
                                '${date.day.toString().padLeft(2, '0')}';
                            final isLatestProfilePhoto =
                                doc.id == latestProfilePhotoId;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildImagePreviewCard(doc),
                                const SizedBox(height: 4),
                                Text(
                                  '${loc.get('uploaded_on')}: $formattedDate',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isLatestProfilePhoto)
                                  Text(
                                    loc.get('latest_photo'),
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ...otherDocuments.map((doc) {
                    final date = doc.uploadedAt;
                    final formattedDate =
                        '${date.year}-'
                        '${date.month.toString().padLeft(2, '0')}-'
                        '${date.day.toString().padLeft(2, '0')}';
                    final isLatestProfilePhoto = doc.id == latestProfilePhotoId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        doc.type == 'Profile'
                            ? Icons.account_circle_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(
                        doc.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${loc.get('uploaded_on')}: $formattedDate'
                        '${isLatestProfilePhoto ? ' • ${loc.get('latest_photo')}' : ''}',
                      ),
                      trailing: IconButton(
                        tooltip: loc.get('delete'),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => deleteDocumentWithConfirmation(doc),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorshipStep() {
    final loc = AppLocalizations.of(context);
    final canAddSponsor =
        orphanSponsorshipStatus == 'sponsored' ||
        orphanSponsorshipStatus == 'candidate';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(loc.get('sponsor_section_title')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: ['sponsored', 'candidate', 'unsponsored'].contains(orphanSponsorshipStatus)
                ? orphanSponsorshipStatus
                : 'unsponsored',
            decoration: InputDecoration(
              labelText: 'حالة اليتيم',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.verified_user_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'sponsored', child: Text('مكفول')),
              DropdownMenuItem(value: 'candidate', child: Text('مرشح للكفالة')),
              DropdownMenuItem(value: 'unsponsored', child: Text('غير مكفول')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => orphanSponsorshipStatus = value);
            },
          ),
          const SizedBox(height: 16),
          if (canAddSponsor)
            ElevatedButton.icon(
              onPressed: _showAddSponsorDialog,
              icon: const Icon(Icons.person_add),
              label: Text(loc.get('add_sponsor')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          const SizedBox(height: 16),
          // Display added sponsors
          if (sponsors.isNotEmpty) ...[
            Text(
              '${loc.get('sponsor_added')} (${sponsors.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            // Sponsors Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.green.shade100,
                ),
                dataRowHeight: 60,
                columns: [
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_name'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_amount'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_currency'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_start_date'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_status'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.get('sponsor_table_actions'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                rows:
                    sponsors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sponsor = entry.value;

                      final statusText =
                          sponsor.isOngoing
                              ? loc.get('sponsor_status_ongoing')
                              : '${loc.get('sponsor_status_ended')}: ${sponsor.endDate?.toIso8601String().split('T')[0] ?? 'N/A'}';

                      final statusColor =
                          sponsor.isOngoing ? Colors.green : Colors.orange;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              sponsor.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              sponsor.amount.toString(),
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              sponsor.currency,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              sponsor.startDate.toIso8601String().split('T')[0],
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!sponsor.isOngoing &&
                                    (sponsor.endReason ?? '').isNotEmpty)
                                  Text(
                                    sponsor.endReason!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  tooltip: loc.get('sponsor_edit'),
                                  onPressed: () {
                                    _showEditSponsorDialog(index, sponsor);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: loc.get('sponsor_delete'),
                                  onPressed: () {
                                    setState(() => sponsors.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSponsorDialog() {
    if (sponsors.any((sponsor) => sponsor.isOngoing)) return;
    final loc = AppLocalizations.of(context);
    final sponsorAmountCtl = TextEditingController();
    final sponsorStartDateCtl = TextEditingController();
    final sponsorEndDateCtl = TextEditingController();
    final sponsorEndReasonCtl = TextEditingController();
    String selectedCategory = 'individual';
    List<Sponsor> sponsorsForCategory() =>
        masterSponsors
            .where((sponsor) => sponsor.sponsorCategory == selectedCategory)
            .toList();
    String? selectedSponsorName =
        sponsorsForCategory().isEmpty ? null : sponsorsForCategory().first.name;
    Sponsor? selectedMasterSponsor() {
      for (final sponsor in sponsorsForCategory()) {
        if (sponsor.name == selectedSponsorName) return sponsor;
      }
      return null;
    }

    String? selectedCurrency = 'شيكل';
    bool isOngoing = true;
    final initialMaster = selectedMasterSponsor();
    if (initialMaster != null) {
      sponsorAmountCtl.text = initialMaster.amount.toString();
      selectedCurrency = initialMaster.currency;
    }
    if (selectedCurrency != null && !currencies.contains(selectedCurrency)) {
      currencies.add(selectedCurrency!);
    }

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: _textDirection,
            child: StatefulBuilder(
              builder: (context, setState) {
                final availableSponsors = sponsorsForCategory();
                final selectedMaster = selectedMasterSponsor();
                final sponsorNames =
                    availableSponsors
                        .map((sponsor) => sponsor.name)
                        .toSet()
                        .toList();
                return AlertDialog(
                  title: const Text('اضافة كفيل'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: loc.get('sponsor_entity_type'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business_outlined),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'individual',
                              child: Text(loc.get('sponsor_individual')),
                            ),
                            DropdownMenuItem(
                              value: 'institution',
                              child: Text(loc.get('sponsor_institution')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedCategory = value;
                              final categorySponsors = sponsorsForCategory();
                              selectedSponsorName =
                                  categorySponsors.isEmpty
                                      ? null
                                      : categorySponsors.first.name;
                              final linkedSponsor = selectedMasterSponsor();
                              sponsorAmountCtl.text =
                                  linkedSponsor?.amount.toString() ?? '';
                              selectedCurrency =
                                  linkedSponsor?.currency ?? 'شيكل';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedSponsorName,
                          decoration: InputDecoration(
                            labelText:
                                selectedCategory == 'institution'
                                    ? loc.get('sponsor_institution_name')
                                    : loc.get('sponsor_name'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              selectedCategory == 'institution'
                                  ? Icons.business
                                  : Icons.person,
                            ),
                          ),
                          items: [
                            ...sponsorNames.map((sponsor) {
                              return DropdownMenuItem(
                                value: sponsor,
                                child: Text(sponsor),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSponsorName = value;
                              final linkedSponsor = selectedMasterSponsor();
                              sponsorAmountCtl.text =
                                  linkedSponsor?.amount.toString() ?? '';
                              selectedCurrency =
                                  linkedSponsor?.currency ?? 'شيكل';
                            });
                          },
                        ),
                        if (selectedMaster != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((selectedMaster.address ?? '').isNotEmpty)
                                    Text(
                                      '${loc.get('address')}: ${selectedMaster.address}',
                                    ),
                                  if ((selectedMaster.phone ?? '').isNotEmpty)
                                    Text(
                                      '${loc.get('phone')}: ${selectedMaster.phone}',
                                    ),
                                  if ((selectedMaster.email ?? '').isNotEmpty)
                                    Text(
                                      '${loc.get('email')}: ${selectedMaster.email}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(loc.get('no_data')),
                          ),
                        const SizedBox(height: 12),

                        // Amount
                        TextField(
                          controller: sponsorAmountCtl,
                          decoration: const InputDecoration(
                            labelText: 'المبلغ الشهري',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // Currency Dropdown with Add Button
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'العملة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                items: [
                                  ...currencies.map(
                                    (currency) => DropdownMenuItem(
                                      value: currency,
                                      child: Text(currency),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: '_add_new_currency_',
                                    child: Text('إضافة عملة جديدة'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == '_add_new_currency_') {
                                    _showAddCurrencyDialog();
                                  } else {
                                    setState(
                                      () => selectedCurrency = value ?? 'شيكل',
                                    );
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: loc.get('edit_currency_name'),
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                _showEditCurrencyDialog(
                                  currentCurrency: selectedCurrency ?? 'شيكل',
                                  onSave:
                                      (currency) => setState(
                                        () => selectedCurrency = currency,
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Start Date
                        TextField(
                          controller: sponsorStartDateCtl,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ البداية (YYYY-MM-DD)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              sponsorStartDateCtl.text =
                                  date.toIso8601String().split('T')[0];
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Ongoing Toggle
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'الكفالة مستمرة؟',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Switch(
                              value: isOngoing,
                              onChanged: (value) {
                                setState(() => isOngoing = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Conditional End Date (shown only if not ongoing)
                        if (!isOngoing)
                          TextField(
                            controller: sponsorEndDateCtl,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الانتهاء (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                sponsorEndDateCtl.text =
                                    date.toIso8601String().split('T')[0];
                              }
                            },
                          ),
                        if (!isOngoing) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: sponsorEndReasonCtl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: loc.get('sponsor_end_reason'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('الغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedSponsorName == null ||
                            selectedSponsorName!.isEmpty ||
                            sponsorAmountCtl.text.trim().isEmpty ||
                            sponsorStartDateCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('يرجى ملء جميع الحقول'),
                            ),
                          );
                          return;
                        }

                        // Validate end date if not ongoing
                        if (!isOngoing &&
                            sponsorEndDateCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('يرجى تحديد تاريخ الانتهاء'),
                            ),
                          );
                          return;
                        }
                        if (!isOngoing &&
                            sponsorEndReasonCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(loc.get('sponsor_end_reason')),
                            ),
                          );
                          return;
                        }

                        // استخدام this.setState للتأكد من تحديث الـ State الرئيسي
                        (this as dynamic).setState(() {
                          final masterSponsor = selectedMasterSponsor()!;

                          sponsors.insert(
                            0,
                            Sponsor(
                              id: const Uuid().v4(),
                              name: selectedSponsorName ?? '',
                              linkedSponsorId: masterSponsor.id,
                              sponsorCategory: masterSponsor.sponsorCategory,
                              organizationName: masterSponsor.organizationName,
                              address: masterSponsor.address,
                              phone: masterSponsor.phone,
                              email: masterSponsor.email,
                              amount:
                                  double.tryParse(sponsorAmountCtl.text) ?? 0,
                              startDate: DateTime.parse(
                                sponsorStartDateCtl.text,
                              ),
                              endDate:
                                  !isOngoing &&
                                          sponsorEndDateCtl.text.isNotEmpty
                                      ? DateTime.parse(sponsorEndDateCtl.text)
                                      : null,
                              endReason:
                                  isOngoing
                                      ? null
                                      : sponsorEndReasonCtl.text.trim(),
                              currency: selectedCurrency ?? 'شيكل',
                              isOngoing: isOngoing,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('اضافة'),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showAddCurrencyDialog() {
    final currencyCtl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: _textDirection,
            child: AlertDialog(
              title: const Text('اضافة عملة جديدة'),
              content: TextField(
                controller: currencyCtl,
                decoration: const InputDecoration(
                  labelText: 'اسم العملة',
                  border: OutlineInputBorder(),
                  hintText: 'مثال: الريال السعودي',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('الغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currencyCtl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('يرجى ادخال اسم العملة'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (!currencies.contains(currencyCtl.text.trim())) {
                        currencies.add(currencyCtl.text.trim());
                      }
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت اضافة العملة: ${currencyCtl.text}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('اضافة'),
                ),
              ],
            ),
          ),
    );
  }

  void _showEditCurrencyDialog({
    required String currentCurrency,
    required ValueChanged<String> onSave,
  }) {
    final loc = AppLocalizations.of(context);
    final currencyCtl = TextEditingController(text: currentCurrency);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(loc.get('edit_currency_name')),
            content: TextField(
              controller: currencyCtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.get('add_sponsor_currency'),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(loc.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  final currency = currencyCtl.text.trim();
                  if (currency.isEmpty) return;
                  if (!currencies.contains(currency)) currencies.add(currency);
                  onSave(currency);
                  Navigator.pop(dialogContext);
                },
                child: Text(loc.get('save')),
              ),
            ],
          ),
    );
  }

  void _showEditSponsorDialog(int index, Sponsor sponsor) {
    final loc = AppLocalizations.of(context);
    final sponsorAmountCtl = TextEditingController(
      text: sponsor.amount.toString(),
    );
    final sponsorStartDateCtl = TextEditingController(
      text: sponsor.startDate.toIso8601String().split('T')[0],
    );
    final sponsorEndDateCtl = TextEditingController(
      text: sponsor.endDate?.toIso8601String().split('T')[0] ?? '',
    );
    final sponsorEndReasonCtl = TextEditingController(
      text: sponsor.endReason ?? '',
    );
    String? selectedCurrency = sponsor.currency;
    if (!currencies.contains(selectedCurrency))
      currencies.add(selectedCurrency!);
    var selectedCategory = sponsor.sponsorCategory;
    bool isOngoing = sponsor.isOngoing;

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: _textDirection,
            child: StatefulBuilder(
              builder: (context, setState) {
                final namesForCategory =
                    masterSponsors
                        .where(
                          (master) =>
                              master.sponsorCategory == selectedCategory,
                        )
                        .map((master) => master.name)
                        .toSet()
                        .toList();
                return AlertDialog(
                  title: Text(loc.get('sponsor_edit')),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: loc.get('sponsor_entity_type'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'individual',
                              child: Text(loc.get('sponsor_individual')),
                            ),
                            DropdownMenuItem(
                              value: 'institution',
                              child: Text(loc.get('sponsor_institution')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedCategory = value;
                              sponsor.sponsorCategory = value;
                              final categorySponsors =
                                  masterSponsors
                                      .where(
                                        (master) =>
                                            master.sponsorCategory == value,
                                      )
                                      .toList();
                              if (categorySponsors.isNotEmpty) {
                                final master = categorySponsors.first;
                                sponsor.name = master.name;
                                sponsor.linkedSponsorId = master.id;
                                sponsor.organizationName =
                                    master.organizationName;
                                sponsor.address = master.address;
                                sponsor.phone = master.phone;
                                sponsor.email = master.email;
                                sponsorAmountCtl.text =
                                    master.amount.toString();
                                selectedCurrency = master.currency;
                              } else {
                                sponsor.name = '';
                                sponsor.linkedSponsorId = null;
                                sponsor.organizationName = null;
                                sponsor.address = null;
                                sponsor.phone = null;
                                sponsor.email = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              namesForCategory.contains(sponsor.name)
                                  ? sponsor.name
                                  : null,
                          decoration: InputDecoration(
                            labelText:
                                selectedCategory == 'institution'
                                    ? loc.get('sponsor_institution_name')
                                    : loc.get('sponsor_name'),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              selectedCategory == 'institution'
                                  ? Icons.business
                                  : Icons.person,
                            ),
                          ),
                          items: [
                            ...namesForCategory.map((name) {
                              return DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              final masterSponsor = masterSponsors.firstWhere(
                                (master) =>
                                    master.sponsorCategory ==
                                        selectedCategory &&
                                    master.name == value,
                              );
                              sponsor.name = value;
                              sponsor.linkedSponsorId = masterSponsor.id;
                              sponsor.organizationName =
                                  masterSponsor.organizationName;
                              sponsor.address = masterSponsor.address;
                              sponsor.phone = masterSponsor.phone;
                              sponsor.email = masterSponsor.email;
                              sponsorAmountCtl.text =
                                  masterSponsor.amount.toString();
                              selectedCurrency = masterSponsor.currency;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Amount
                        TextField(
                          controller: sponsorAmountCtl,
                          decoration: InputDecoration(
                            labelText: loc.get('sponsor_table_amount'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // Currency Dropdown
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCurrency,
                                decoration: InputDecoration(
                                  labelText: loc.get('sponsor_table_currency'),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                                items: [
                                  ...currencies.map(
                                    (currency) => DropdownMenuItem(
                                      value: currency,
                                      child: Text(currency),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: '_add_new_currency_',
                                    child: Text('إضافة عملة جديدة'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == '_add_new_currency_') {
                                    _showAddCurrencyDialog();
                                  } else {
                                    setState(
                                      () =>
                                          selectedCurrency =
                                              value ?? sponsor.currency,
                                    );
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: loc.get('edit_currency_name'),
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                _showEditCurrencyDialog(
                                  currentCurrency:
                                      selectedCurrency ?? sponsor.currency,
                                  onSave:
                                      (currency) => setState(
                                        () => selectedCurrency = currency,
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Start Date
                        TextField(
                          controller: sponsorStartDateCtl,
                          decoration: InputDecoration(
                            labelText: loc.get('sponsor_table_start_date'),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: sponsor.startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              sponsorStartDateCtl.text =
                                  date.toIso8601String().split('T')[0];
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Ongoing Toggle
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'الكفالة مستمرة؟',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Switch(
                              value: isOngoing,
                              onChanged: (value) {
                                setState(() {
                                  isOngoing = value;
                                  if (value) {
                                    sponsorEndDateCtl.clear();
                                    sponsorEndReasonCtl.clear();
                                  } else if (sponsorEndDateCtl.text.isEmpty) {
                                    sponsorEndDateCtl.text =
                                        DateTime.now().toIso8601String().split(
                                          'T',
                                        )[0];
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Conditional End Date
                        if (!isOngoing)
                          TextField(
                            controller: sponsorEndDateCtl,
                            decoration: InputDecoration(
                              labelText: 'تاريخ الانتهاء (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: sponsor.endDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                sponsorEndDateCtl.text =
                                    date.toIso8601String().split('T')[0];
                              }
                            },
                          ),
                        if (!isOngoing) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: sponsorEndReasonCtl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: loc.get('sponsor_end_reason'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.get('cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (sponsorAmountCtl.text.trim().isEmpty ||
                            sponsorStartDateCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('يرجى ملء جميع الحقول'),
                            ),
                          );
                          return;
                        }

                        if (!isOngoing &&
                            sponsorEndDateCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('يرجى تحديد تاريخ الانتهاء'),
                            ),
                          );
                          return;
                        }
                        if (!isOngoing &&
                            sponsorEndReasonCtl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(loc.get('sponsor_end_reason')),
                            ),
                          );
                          return;
                        }

                        (this as dynamic).setState(() {
                          sponsors[index] = Sponsor(
                            id: sponsor.id,
                            name: sponsor.name,
                            linkedSponsorId: sponsor.linkedSponsorId,
                            sponsorCategory: sponsor.sponsorCategory,
                            organizationName: sponsor.organizationName,
                            address: sponsor.address,
                            phone: sponsor.phone,
                            email: sponsor.email,
                            amount: double.tryParse(sponsorAmountCtl.text) ?? 0,
                            startDate: DateTime.parse(sponsorStartDateCtl.text),
                            endDate:
                                !isOngoing && sponsorEndDateCtl.text.isNotEmpty
                                    ? DateTime.parse(sponsorEndDateCtl.text)
                                    : null,
                            endReason:
                                isOngoing
                                    ? null
                                    : sponsorEndReasonCtl.text.trim(),
                            currency: selectedCurrency ?? sponsor.currency,
                            isOngoing: isOngoing,
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: Text(loc.get('save')),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  Widget _buildPaymentsStep() {
    final loc = AppLocalizations.of(context);

    // Filter only ongoing sponsors for the dialog
    final ongoingSponsors =
        sponsors.where((sponsor) => sponsor.isOngoing).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.get('payment_records'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AddPaymentDialog(
                          currencies: currencies,
                          selectedCurrency: selectedCurrency,
                          ongoingSponsors: ongoingSponsors,
                          onSave: (payment) {
                            setState(() {
                              payments.add(payment);
                            });
                          },
                        ),
                  );
                },
                icon: const Icon(Icons.add_card, size: 20),
                label: Text(loc.get('add_payment')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (payments.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.blue.shade50.withOpacity(0.5),
                    ),
                    dataRowHeight: 56,
                    horizontalMargin: 20,
                    columnSpacing: 28,
                    columns: [
                      DataColumn(
                        label: Text(
                          loc.get('payment_date'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          loc.get('amount_label'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          loc.get('add_sponsor_currency'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          loc.get('sponsor_label'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          loc.get('payment_note'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '', // Actions
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        payments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final payment = entry.value;

                          // Find sponsor name for this payment
                          String sponsorName = loc.get('not_available_label');
                          if (payment.sponsorId != null) {
                            try {
                              final sp = sponsors.firstWhere(
                                (s) => s.id == payment.sponsorId,
                              );
                              sponsorName = sp.name;
                            } catch (_) {}
                          }

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (index % 2 == 0) return Colors.white;
                              return Colors.grey.shade50;
                            }),
                            cells: [
                              DataCell(
                                Text(
                                  payment.paidAt.toIso8601String().split(
                                    'T',
                                  )[0],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    payment.amount.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment.currency ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  sponsorName,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 150,
                                  ),
                                  child: Text(
                                    payment.note ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue.shade400,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () => _editPayment(index, payment),
                                      tooltip: loc.get('edit'),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade300,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _showDeletePaymentConfirmation(
                                          index,
                                          payment,
                                        );
                                      },
                                      tooltip: loc.get('delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.get('no_payments_recorded'),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _editPayment(int index, payment) {
    final ongoingSponsors =
        sponsors.where((sponsor) => sponsor.isOngoing).toList();

    showDialog(
      context: context,
      builder:
          (context) => AddPaymentDialog(
            currencies: currencies,
            selectedCurrency: payment.currency,
            ongoingSponsors: ongoingSponsors,
            payment: payment,
            onSave: (updatedPayment) {
              setState(() {
                payments[index] = updatedPayment;
              });
            },
          ),
    );
  }

  void _showDeletePaymentConfirmation(int index, payment) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.get('delete')),
            content: Text(
              '${loc.get('are_you_sure_delete')} ${payment.amount} ${payment.currency}؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    payments.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.get('delete')),
              ),
            ],
          ),
    );
  }

  Widget _buildReportingStep() {
    final loc = AppLocalizations.of(context);
    final financialAvailable = payments.any((payment) => payment.amount > 0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('الاستمارة'),
          const SizedBox(height: 16),
          if (financialAvailable)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: includeFinancialDataInReport,
              onChanged:
                  (value) =>
                      setState(() => includeFinancialDataInReport = value),
              title: const Text('إدراج بيانات الدفعات في الاستمارة'),
              subtitle: const Text('يتضمن ذلك الدفعات المسجلة فقط.'),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد دفعات مستلمة؛ لن تُدرج مبالغ مالية في الاستمارة.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص الاستمارة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFormPreviewCard(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _previewFormPdf,
            icon: const Icon(Icons.preview),
            label: const Text('معاينة الاستمارة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                () => generatePdfReport(
                  includePayments: includeFinancialDataInReport,
                ),
            icon: const Icon(Icons.file_download),
            label: const Text('إنشاء ملف PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                () => generatePdfReport(
                  includePayments: includeFinancialDataInReport,
                ),
            icon: const Icon(Icons.print),
            label: Text(loc.get('print')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPreviewCard() {
    final reportPayments =
        payments.where((payment) => payment.amount > 0).toList();
    final name = [
      firstNameCtl.text.trim(),
      fatherNameCtl.text.trim(),
      familyNameCtl.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    final sponsorName = sponsors.isNotEmpty ? sponsors.first.name : 'غير مكفول';
    final sponsorStatus =
        orphanSponsorshipStatus == 'sponsored'
            ? 'مكفول'
            : orphanSponsorshipStatus == 'candidate'
            ? 'مرشح للكفالة'
            : 'غير مكفول';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.isNotEmpty ? name : 'اسم اليتيم غير محدد',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPreviewRow(
              'الهوية',
              childIdCtl.text.isNotEmpty ? childIdCtl.text : 'غير محددة',
            ),
            _buildPreviewRow(
              'تاريخ الميلاد',
              birthDateCtl.text.isNotEmpty ? birthDateCtl.text : 'غير محدد',
            ),
            _buildPreviewRow('الجنس', gender == 'M' ? 'ذكر' : 'أنثى'),
            _buildPreviewRow('حالة الكفالة', sponsorStatus),
            _buildPreviewRow('اسم الكفيل', sponsorName),
            if (includeFinancialDataInReport && reportPayments.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'البيانات المالية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              ...reportPayments.map((payment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${payment.amount} ${payment.currency ?? ''} • ${payment.paidAt.toLocal().toIso8601String().split('T')[0]}',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _previewFormPdf() async {
    final pdfBytes = await generatePdfPreviewBytes(
      includePayments: includeFinancialDataInReport,
    );
    if (pdfBytes == null || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: const Text('معاينة الاستمارة')),
              body: PdfPreview(
                build: (_) async => pdfBytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
              ),
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateToDDMMYYYY(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

  int _calculateAge(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 0;
    }
    try {
      final birthDate = DateTime.parse(dateString);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  /// Build image preview card with delete functionality
  Widget _buildImagePreviewCard(Document doc) {
    return FutureBuilder<String?>(
      future: resolveAttachmentImagePath(doc),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint(
            'Could not resolve attachment image path: ${snapshot.error}',
          );
        }
        return _buildResolvedImagePreviewCard(doc, snapshot.data ?? '');
      },
    );
  }

  Widget _buildResolvedImagePreviewCard(Document doc, String resolvedFilePath) {
    final loc = AppLocalizations.of(context);
    final filePath = resolvedFilePath;
    final fileName = doc.fileName;
    final docId = doc.id;

    final isNetworkImage =
        filePath.startsWith('http') || filePath.startsWith('blob:');
    final isLocalFile = filePath.isNotEmpty && !isNetworkImage;

    // Check if file exists (on Web we assume network/blob images are handled by errorBuilder)
    bool fileExists = true;
    if (!kIsWeb && isLocalFile) {
      fileExists = File(filePath).existsSync();
    }

    if (filePath.isEmpty || (isLocalFile && !fileExists)) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_present, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 4),
            Text(
              loc.get('file_not_found'),
              style: TextStyle(fontSize: 10, color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Verify file exists before displaying (only for local files on Desktop/Mobile)
    final imageFile = (!kIsWeb && isLocalFile) ? File(filePath) : null;
    if (!kIsWeb &&
        isLocalFile &&
        (imageFile == null || !imageFile.existsSync())) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.red.shade400,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              loc.get('not_available_label'),
              style: TextStyle(fontSize: 10, color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      key: ValueKey(docId),
      onTap: () {
        // Show full screen preview on tap
        if (filePath.isEmpty) return;
        showDialog(
          context: context,
          builder:
              (ctx) => Dialog(
                backgroundColor: Colors.black,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Stack(
                    children: [
                      Center(
                        child: UniversalImage(
                          path: filePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
      child: Tooltip(
        message:
            fileName.isNotEmpty ? fileName : '${loc.get('image')} - $docId',
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: UniversalImage(
                  path: filePath,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                  errorWidget: Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.get('error'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => deleteDocumentWithConfirmation(doc),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
            // Checkmark to indicate successful upload
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build photo upload card
  Widget _buildPhotoUploadCard({
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool hasUploaded = false,
    bool showTitle = true,
  }) {
    final loc = AppLocalizations.of(context);
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTitle) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.photo_camera),
                label: Text(loc.get('upload_button')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
        if (hasUploaded)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomCauseDialog(bool isFather) async {
    final loc = AppLocalizations.of(context);
    String customCause = '';
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.get('add_custom_cause')),
            content: TextFormField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.get('death_cause'),
                hintText: loc.get('add_custom_cause'),
              ),
              onChanged: (val) => customCause = val,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (customCause.isNotEmpty) {
                    setState(() {
                      if (isFather) {
                        fatherDeathCause = customCause;
                      } else {
                        motherDeathCause = customCause;
                      }
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text(loc.get('add_button')),
              ),
            ],
          ),
    );
  }
}
