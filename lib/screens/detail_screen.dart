import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../utils/brands.dart';
import '../utils/currencies.dart';

class DetailScreen extends StatefulWidget {
  final Subscription subscription;

  const DetailScreen({super.key, required this.subscription});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final HiveService _hiveService = HiveService();
  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');

  Widget _infoRow(
    AppColors colors,
    String label,
    String value, {
    bool strikeThrough = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: colors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: colors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: strikeThrough
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _hiveService.delete(id);
    if (mounted) {
      Navigator.of(context).pop();
    }
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
          'DETAILS',
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
      body: ValueListenableBuilder<Box<Subscription>>(
        valueListenable: _hiveService.box.listenable(
          keys: [widget.subscription.id],
        ),
        builder: (context, box, _) {
          final sub = box.get(widget.subscription.id) ?? widget.subscription;
          final hasBrand =
              sub.brandKey != null && Brands.all.containsKey(sub.brandKey);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Opacity(
                            opacity: sub.isPaused ? 0.5 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.foreground,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (hasBrand) ...[
                                    BrandIcon(brandKey: sub.brandKey, size: 52),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.name,
                                          style: GoogleFonts.inter(
                                            color: colors.foreground,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (sub.isFreeTrial || sub.isPaused) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              if (sub.isFreeTrial)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: colors.badgeBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    sub.isTrialActive()
                                                        ? 'Trial'
                                                        : 'Trial Ended',
                                                    style: GoogleFonts.inter(
                                                      color: colors.badgeText,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              if (sub.isPaused)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: colors.badgeBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Paused',
                                                    style: GoogleFonts.inter(
                                                      color: colors.badgeText,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<String>(
                            valueListenable: HiveService.currencyCodeNotifier,
                            builder: (context, currencyCode, _) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.cardBorderSubtle,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _infoRow(
                                      colors,
                                      'Cost',
                                      AppCurrencies.format(
                                        sub.cost,
                                        currencyCode,
                                      ),
                                      strikeThrough: sub.isPaused,
                                    ),
                                    Container(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                    _infoRow(
                                      colors,
                                      'Monthly Equivalent',
                                      '${AppCurrencies.format(sub.monthlyCost, currencyCode)} / mo',
                                      strikeThrough: sub.isPaused,
                                    ),
                                    Container(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                    _infoRow(
                                      colors,
                                      'Billing Cycle',
                                      sub.cycle,
                                    ),
                                    Container(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                    _infoRow(
                                      colors,
                                      'Billing Date',
                                      _dateFormat.format(sub.billingDate),
                                    ),
                                    Container(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                    _infoRow(
                                      colors,
                                      'Free Trial',
                                      sub.isTrialActive()
                                          ? 'Active'
                                          : (sub.isFreeTrial
                                                ? 'Ended (Paid)'
                                                : 'No'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Material(
                            color: colors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colors.cardBorderSubtle,
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                SwitchListTile(
                                  key: const Key('detail_free_trial_switch'),
                                  value: sub.isFreeTrial,
                                  onChanged: (value) async {
                                    await _hiveService.toggleFreeTrial(
                                      sub.id,
                                      value,
                                    );
                                  },
                                  title: Text(
                                    'Free Trial',
                                    style: GoogleFonts.inter(
                                      color: colors.foreground,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    sub.isTrialActive()
                                        ? 'Excluded from budget until trial ends'
                                        : (sub.isFreeTrial
                                              ? 'Trial ended · Included in budget'
                                              : 'Mark as free trial'),
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
                                SwitchListTile(
                                  value: sub.isPaused,
                                  onChanged: (value) async {
                                    await _hiveService.togglePause(
                                      sub.id,
                                      value,
                                    );
                                  },
                                  title: Text(
                                    'Pause Subscription',
                                    style: GoogleFonts.inter(
                                      color: colors.foreground,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    sub.isPaused
                                        ? 'Excluded from Total / mo'
                                        : 'Included in Total / mo',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _delete(sub.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.foreground,
                        backgroundColor: colors.background,
                        side: BorderSide(color: colors.foreground, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'DELETE',
                        style: GoogleFonts.inter(
                          color: colors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
