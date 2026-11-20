import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../utils/currencies.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final HiveService _hiveService = HiveService();
  late final TextEditingController _budgetController;
  static const List<double> _presets = [25, 50, 100, 200, 500, 1000];
  static const List<String> _quickCurrencyCodes = [
    'USD',
    'PKR',
    'EUR',
    'SAR',
    'GBP',
    'AED',
    'INR',
  ];

  @override
  void initState() {
    super.initState();
    final current = _hiveService.getMaxBudget();
    _budgetController = TextEditingController(text: _formatBudgetInput(current));
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String _formatBudgetInput(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  InputDecoration _fieldDecoration(
    AppColors colors,
    String label, {
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(
        color: colors.foreground,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.inter(
        color: colors.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.inter(
        color: colors.mutedText,
        fontSize: 13,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: colors.foreground,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: GoogleFonts.inter(
        color: colors.badgeText,
        fontSize: 12,
      ),
      filled: true,
      fillColor: colors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.foreground, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.foreground, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.foreground, width: 1.5),
      ),
    );
  }

  Future<void> _selectPreset(double amount) async {
    setState(() {
      _budgetController.text = _formatBudgetInput(amount);
      _budgetController.selection = TextSelection.fromPosition(
        TextPosition(offset: _budgetController.text.length),
      );
    });
    await _hiveService.setMaxBudget(amount);
  }

  Future<void> _stepBudget(double delta) async {
    final current =
        double.tryParse(_budgetController.text.trim()) ??
        _hiveService.getMaxBudget();
    final next = (current + delta).clamp(1.0, 1000000.0);
    await _selectPreset(next);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    final parsed = double.parse(_budgetController.text.trim());
    await _hiveService.setMaxBudget(parsed);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSegmentOption({
    required AppColors colors,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.foreground : colors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? colors.onForeground : colors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.inter(
            color: colors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.divider),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: HiveService.currencyCodeNotifier,
          builder: (context, currencyCode, _) {
            final activeCurrency = AppCurrencies.byCode(currencyCode);
            final symbolPrefix = '${activeCurrency.symbol.trim()} ';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Maximum Subscription Budget',
                      style: GoogleFonts.inter(
                        color: colors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set your monthly subscription spending ceiling (e.g., ${symbolPrefix.trim()}50/month).',
                      style: GoogleFonts.inter(
                        color: colors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('budget_input'),
                            controller: _budgetController,
                            style: GoogleFonts.inter(
                              color: colors.foreground,
                              fontSize: 15,
                            ),
                            cursorColor: colors.foreground,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _fieldDecoration(
                              colors,
                              'Monthly Ceiling',
                              prefixText: symbolPrefix,
                              suffixText: '/ mo',
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.trim());
                              if (parsed != null && parsed > 0) {
                                _hiveService.setMaxBudget(parsed);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a monthly budget';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Enter an amount greater than 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 54,
                          child: Row(
                            children: [
                              InkWell(
                                key: const Key('budget_decrement'),
                                onTap: () => _stepBudget(-10),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 44,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 18,
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                key: const Key('budget_increment'),
                                onTap: () => _stepBudget(10),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 44,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<double>(
                      valueListenable: HiveService.maxBudgetNotifier,
                      builder: (context, currentBudget, _) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _presets.map((preset) {
                            final isSelected =
                                (currentBudget - preset).abs() < 0.001;
                            return InkWell(
                              onTap: () => _selectPreset(preset),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.foreground
                                      : colors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.foreground
                                        : colors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$symbolPrefix${preset.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? colors.onForeground
                                        : colors.foreground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.foreground,
                          foregroundColor: colors.onForeground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'SAVE BUDGET',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      key: const Key('currency_section'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Currency',
                          style: GoogleFonts.inter(
                            color: colors.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose the currency displayed across totals, budgets, and subscriptions.',
                          style: GoogleFonts.inter(
                            color: colors.mutedText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        KeyedSubtree(
                          key: ValueKey('currency_dropdown_wrap_$currencyCode'),
                          child: DropdownButtonFormField<String>(
                            key: const Key('currency_dropdown'),
                            initialValue: currencyCode,
                            dropdownColor: colors.surface,
                            iconEnabledColor: colors.foreground,
                            isExpanded: true,
                            style: GoogleFonts.inter(
                              color: colors.foreground,
                              fontSize: 14,
                            ),
                            decoration: _fieldDecoration(
                              colors,
                              'Display Currency',
                            ),
                            items: AppCurrencies.all.map((option) {
                              return DropdownMenuItem<String>(
                                value: option.code,
                                child: Text(
                                  '${option.code} - ${option.name} (${option.symbol.trim()})',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: colors.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _hiveService.setCurrencyCode(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickCurrencyCodes.map((code) {
                            final option = AppCurrencies.byCode(code);
                            final isSelected = option.code == currencyCode;
                            return InkWell(
                              key: Key('currency_chip_${option.code}'),
                              onTap: () =>
                                  _hiveService.setCurrencyCode(option.code),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.foreground
                                      : colors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.foreground
                                        : colors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${option.code} (${option.symbol.trim()})',
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? colors.onForeground
                                        : colors.foreground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Appearance',
                      style: GoogleFonts.inter(
                        color: colors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: HiveService.isDarkModeNotifier,
                      builder: (context, isDark, _) {
                        return Material(
                          color: colors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: colors.border, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: isDark,
                                onChanged: (value) =>
                                    _hiveService.setIsDarkMode(value),
                                title: Text(
                                  'Dark Mode',
                                  style: GoogleFonts.inter(
                                    color: colors.foreground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Toggle between dark and light mode',
                                  style: GoogleFonts.inter(
                                    color: colors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                                activeThumbColor: colors.onForeground,
                                activeTrackColor: colors.foreground,
                                inactiveThumbColor: colors.mutedText,
                                inactiveTrackColor: colors.inactiveTrack,
                                trackOutlineColor: WidgetStateProperty.all(
                                  colors.border,
                                ),
                              ),
                              Container(height: 1, color: colors.divider),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildSegmentOption(
                                        colors: colors,
                                        label: 'DARK',
                                        selected: isDark,
                                        onTap: () =>
                                            _hiveService.setIsDarkMode(true),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildSegmentOption(
                                        colors: colors,
                                        label: 'LIGHT',
                                        selected: !isDark,
                                        onTap: () =>
                                            _hiveService.setIsDarkMode(false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
