import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../utils/brands.dart';
import '../utils/currencies.dart';
import 'add_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final HiveService _hiveService = HiveService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  Future<void> _showEditBudgetDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BudgetLimitDialog(hiveService: _hiveService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: HiveService.currencyCodeNotifier,
      builder: (context, currencyCode, _) {
        final currency = AppCurrencies.formatter(currencyCode);

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'SUBTRACKER',
              style: GoogleFonts.inter(
                color: colors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                key: const Key('dashboard_currency_button'),
                tooltip: 'Currency',
                color: colors.surface,
                onSelected: _hiveService.setCurrencyCode,
                itemBuilder: (context) {
                  return AppCurrencies.all.map((option) {
                    final selected = option.code == currencyCode;
                    return PopupMenuItem<String>(
                      value: option.code,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 42,
                            child: Text(
                              option.code,
                              style: GoogleFonts.inter(
                                color: colors.foreground,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${option.name} (${option.symbol.trim()})',
                              style: GoogleFonts.inter(
                                color: selected
                                    ? colors.foreground
                                    : colors.mutedText,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: colors.foreground,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyCode,
                        style: GoogleFonts.inter(
                          color: colors.foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: colors.foreground,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  colors.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: colors.foreground,
                ),
                tooltip: 'Toggle Theme',
                onPressed: _hiveService.toggleTheme,
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: colors.foreground,
                ),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.divider),
            ),
          ),
          body: ValueListenableBuilder<Box<Subscription>>(
            valueListenable: _hiveService.box.listenable(),
            builder: (context, box, _) {
              final subs = box.values.toList()
                ..sort((a, b) => a.billingDate.compareTo(b.billingDate));
              final totalMonthly = _hiveService.calculateActiveMonthly();
              final activeCount = subs.where((s) => !s.isPaused).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total / mo',
                              style: GoogleFonts.inter(
                                color: colors.mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '$activeCount active',
                              style: GoogleFonts.inter(
                                color: colors.subtleText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currency.format(totalMonthly),
                            style: GoogleFonts.inter(
                              color: colors.foreground,
                              fontSize: 54,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2.0,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<double>(
                          valueListenable: HiveService.maxBudgetNotifier,
                          builder: (context, maxBudget, _) {
                            final budget = maxBudget <= 0
                                ? HiveService.defaultMaxBudget
                                : maxBudget;
                            final ratio = totalMonthly / budget;
                            final progress = ratio.clamp(0.0, 1.0);
                            final isOverBudget = totalMonthly > budget;

                            return InkWell(
                              key: const Key('dashboard_budget_tap'),
                              onTap: () => _showEditBudgetDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      key: const Key('budget_progress_bar'),
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: colors.divider,
                                        borderRadius: BorderRadius.circular(3),
                                        border: isOverBudget
                                            ? Border.all(
                                                color: colors.foreground,
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors.foreground,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (isOverBudget)
                                      Container(
                                        key: const Key('over_budget_banner'),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.foreground,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'OVER BUDGET',
                                              style: GoogleFonts.inter(
                                                color: colors.onForeground,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.4,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${currency.format(totalMonthly)} / ${currency.format(budget)}',
                                                  style: GoogleFonts.inter(
                                                    color: colors.onForeground,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 13,
                                                  color: colors.onForeground,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Budget: ${currency.format(budget)} / mo',
                                                style: GoogleFonts.inter(
                                                  color: colors.mutedText,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 14,
                                                color: colors.mutedText,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${(ratio * 100).round()}%',
                                            style: GoogleFonts.inter(
                                              color: colors.subtleText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: colors.divider),
                  Expanded(
                    child: subs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: colors.foreground,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No subscriptions',
                                    style: GoogleFonts.inter(
                                      color: colors.foreground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap + to track your recurring expenses.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: colors.mutedText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: subs.length,
                            itemBuilder: (context, index) {
                              final sub = subs[index];
                              final hasBrand =
                                  sub.brandKey != null &&
                                  Brands.all.containsKey(sub.brandKey);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Opacity(
                                  opacity: sub.isPaused ? 0.5 : 1.0,
                                  child: Material(
                                    color: colors.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: colors.foreground,
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetailScreen(subscription: sub),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            if (hasBrand) ...[
                                              BrandIcon(
                                                brandKey: sub.brandKey,
                                                size: 42,
                                              ),
                                              const SizedBox(width: 14),
                                            ],
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          sub.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: colors
                                                                    .foreground,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      if (sub.isFreeTrial) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 7,
                                                                vertical: 2,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                                border: Border.all(
                                                                  color: colors
                                                                      .badgeBorder,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                          child: Text(
                                                            sub.isTrialActive()
                                                                ? 'Trial'
                                                                : 'Trial Ended',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color: colors
                                                                      .badgeText,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  letterSpacing:
                                                                      0.4,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${_dateFormat.format(sub.billingDate)} · ${sub.cycle}',
                                                    style: GoogleFonts.inter(
                                                      color: colors.mutedText,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  currency.format(sub.cost),
                                                  style: GoogleFonts.inter(
                                                    color: colors.foreground,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    decoration: sub.isPaused
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : TextDecoration.none,
                                                    decorationColor:
                                                        colors.foreground,
                                                    decorationThickness: 2,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  sub.cycle == 'Yearly'
                                                      ? '/ yr'
                                                      : '/ mo',
                                                  style: GoogleFonts.inter(
                                                    color: colors.subtleText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddScreen()),
              );
            },
            backgroundColor: colors.foreground,
            foregroundColor: colors.onForeground,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }
}

class _BudgetLimitDialog extends StatefulWidget {
  final HiveService hiveService;

  const _BudgetLimitDialog({required this.hiveService});

  @override
  State<_BudgetLimitDialog> createState() => _BudgetLimitDialogState();
}

class _BudgetLimitDialogState extends State<_BudgetLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  static const List<double> _presets = [25, 50, 100, 200, 500, 1000, 5000];

  @override
  void initState() {
    super.initState();
    final current = widget.hiveService.getMaxBudget();
    final formatted = current == current.roundToDouble()
        ? current.toStringAsFixed(0)
        : current.toStringAsFixed(2);
    _controller = TextEditingController(text: formatted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final parsed = double.parse(_controller.text.trim());
    await widget.hiveService.setMaxBudget(parsed);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final activeCurrency = AppCurrencies.byCode(
      widget.hiveService.getCurrencyCode(),
    );
    final symbolPrefix = '${activeCurrency.symbol.trim()} ';
    final parsedCurrent = double.tryParse(_controller.text.trim());

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border, width: 1),
      ),
      title: Text(
        'SET BUDGET LIMIT',
        style: GoogleFonts.inter(
          color: colors.foreground,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('dialog_budget_input'),
                controller: _controller,
                autofocus: true,
                style: GoogleFonts.inter(
                  color: colors.foreground,
                  fontSize: 15,
                ),
                cursorColor: colors.foreground,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monthly Ceiling',
                  prefixText: symbolPrefix,
                  prefixStyle: GoogleFonts.inter(
                    color: colors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  suffixText: '/ mo',
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
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colors.foreground,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.foreground, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colors.foreground,
                      width: 1.5,
                    ),
                  ),
                ),
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final isSelected =
                      parsedCurrent != null &&
                      (parsedCurrent - preset).abs() < 0.001;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _controller.text = preset.toStringAsFixed(0);
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.foreground
                            : colors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? colors.foreground : colors.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$symbolPrefix${preset.toStringAsFixed(0)}',
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: GoogleFonts.inter(
              color: colors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('dialog_budget_save'),
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.foreground,
            foregroundColor: colors.onForeground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'SAVE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
