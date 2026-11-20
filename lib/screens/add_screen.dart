import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../utils/brands.dart';
import '../utils/currencies.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Netflix');
  final _costController = TextEditingController();
  final HiveService _hiveService = HiveService();

  String _selectedService = 'Netflix';
  String? _brandKey = 'Netflix';
  DateTime _billingDate = DateTime.now().add(const Duration(days: 7));
  String _cycle = 'Monthly';
  bool _isFreeTrial = false;
  bool _isPaused = false;

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    AppColors colors,
    String label, {
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(
        color: colors.foreground,
        fontSize: 15,
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

  void _onServiceChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedService = value;
      if (value == 'Custom') {
        _brandKey = null;
        _nameController.clear();
      } else {
        _brandKey = value;
        _nameController.text = value;
      }
    });
  }

  Future<void> _pickDate() async {
    final colors = AppColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final pickerScheme = colors.isDark
            ? ColorScheme.dark(
                primary: colors.foreground,
                onPrimary: colors.onForeground,
                surface: colors.surface,
                onSurface: colors.foreground,
              )
            : ColorScheme.light(
                primary: colors.foreground,
                onPrimary: colors.onForeground,
                surface: colors.surface,
                onSurface: colors.foreground,
              );
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: pickerScheme,
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _billingDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final subscription = Subscription(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      cost: double.parse(_costController.text.trim()),
      billingDate: _billingDate,
      cycle: _cycle,
      isFreeTrial: _isFreeTrial,
      isPaused: _isPaused,
      brandKey: _brandKey,
    );

    await _hiveService.add(subscription);
    if (subscription.isFreeTrial) {
      await NotificationService.instance.scheduleTrialAlert(subscription);
    }

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
          'ADD SUBSCRIPTION',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedService,
                  dropdownColor: colors.surface,
                  iconEnabledColor: colors.foreground,
                  style: GoogleFonts.inter(
                    color: colors.foreground,
                    fontSize: 15,
                  ),
                  decoration: _fieldDecoration(colors, 'Popular Services'),
                  items: Brands.serviceOptions.map((service) {
                    final hasBrand = Brands.all.containsKey(service);
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Row(
                        children: [
                          BrandIcon(
                            brandKey: hasBrand ? service : null,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            service,
                            style: GoogleFonts.inter(
                              color: colors.foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onServiceChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    color: colors.foreground,
                    fontSize: 15,
                  ),
                  cursorColor: colors.foreground,
                  decoration: _fieldDecoration(colors, 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a subscription name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String>(
                  valueListenable: HiveService.currencyCodeNotifier,
                  builder: (context, currencyCode, _) {
                    final activeCurrency = AppCurrencies.byCode(currencyCode);
                    return TextFormField(
                      controller: _costController,
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
                        'Cost',
                        prefixText: '${activeCurrency.symbol.trim()} ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a cost';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: _fieldDecoration(colors, 'Billing Date'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(_billingDate),
                          style: GoogleFonts.inter(
                            color: colors.foreground,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: colors.foreground,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _cycle,
                  dropdownColor: colors.surface,
                  iconEnabledColor: colors.foreground,
                  style: GoogleFonts.inter(
                    color: colors.foreground,
                    fontSize: 15,
                  ),
                  decoration: _fieldDecoration(colors, 'Cycle'),
                  items: const ['Monthly', 'Yearly'].map((cycle) {
                    return DropdownMenuItem<String>(
                      value: cycle,
                      child: Text(cycle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _cycle = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Material(
                  color: colors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isFreeTrial,
                        onChanged: (value) =>
                            setState(() => _isFreeTrial = value),
                        title: Text(
                          'Free Trial',
                          style: GoogleFonts.inter(
                            color: colors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Notify 24h before billing · Excluded from budget until trial ends',
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
                        value: _isPaused,
                        onChanged: (value) => setState(() => _isPaused = value),
                        title: Text(
                          'Pause Subscription',
                          style: GoogleFonts.inter(
                            color: colors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Exclude from monthly total',
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
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.foreground,
                      foregroundColor: colors.onForeground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'SAVE SUBSCRIPTION',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
