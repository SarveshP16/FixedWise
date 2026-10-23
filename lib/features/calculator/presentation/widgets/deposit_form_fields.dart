import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../../core/widgets/fixedwise_segmented_control.dart';
import '../../../deposits/domain/compounding_frequency.dart';
import '../../../deposits/domain/draft_deposit.dart';
import '../../../deposits/domain/fixed_deposit.dart' show describeTenure;
import '../../../deposits/domain/payout_type.dart';

/// The fields shared by the standalone Calculator tab and the New Deposit
/// form: Bank, Interest rate, Principal, Tenure (months + extra days),
/// Compounding, Payout type.
/// Owns its own text controllers (the form's source of truth for typed
/// values) and reports every change upward via [onChanged] so the parent
/// screen can recompute its live output panel.
class DepositFormFields extends StatefulWidget {
  const DepositFormFields({
    super.key,
    required this.initial,
    required this.bankSuggestions,
    required this.currencySymbol,
    required this.onChanged,
  });

  final DraftDeposit initial;
  final List<String> bankSuggestions;
  final String currencySymbol;
  final ValueChanged<DraftDeposit> onChanged;

  @override
  State<DepositFormFields> createState() => _DepositFormFieldsState();
}

class _DepositFormFieldsState extends State<DepositFormFields> {
  late DraftDeposit _draft;
  late final TextEditingController _bankController;
  late final TextEditingController _rateController;
  late final TextEditingController _principalController;
  late final TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _bankController = TextEditingController(text: _draft.bankName);
    _rateController = TextEditingController(text: _formatRate(_draft.interestRatePercent));
    _principalController = TextEditingController(text: _formatAmount(_draft.principalAmount));
    _daysController = TextEditingController(text: _draft.tenureDays == 0 ? '' : '${_draft.tenureDays}');
  }

  @override
  void dispose() {
    _bankController.dispose();
    _rateController.dispose();
    _principalController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  String _formatRate(double rate) => rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toString();

  String _formatAmount(double amount) => amount.toStringAsFixed(0);

  void _emit(DraftDeposit next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FixedwiseFieldShell(
          label: 'Bank',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _bankController,
                style: AppTypography.inputText,
                decoration: const InputDecoration(hintText: 'e.g. Axis Bank'),
                onChanged: (value) => _emit(_draft.copyWith(bankName: value)),
              ),
              if (widget.bankSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bank in widget.bankSuggestions.take(6))
                      ActionChip(
                        label: Text(bank),
                        onPressed: () {
                          _bankController.text = bank;
                          _emit(_draft.copyWith(bankName: bank));
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        FixedwiseFieldShell(
          label: 'Interest rate',
          child: TextField(
            controller: _rateController,
            style: AppTypography.inputText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration: const InputDecoration(suffixText: '% p.a.'),
            onChanged: (value) => _emit(_draft.copyWith(interestRatePercent: double.tryParse(value) ?? 0)),
          ),
        ),
        FixedwiseFieldShell(
          label: 'Principal amount',
          child: TextField(
            controller: _principalController,
            style: AppTypography.inputText,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(prefixText: widget.currencySymbol),
            onChanged: (value) => _emit(_draft.copyWith(principalAmount: double.tryParse(value) ?? 0)),
          ),
        ),
        FixedwiseFieldShell(
          label: 'Tenure',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 0–10 years: Indian banks take FDs from 7 days to 10 years.
              Slider(
                value: _draft.tenureMonths.toDouble().clamp(0, 120),
                min: 0,
                max: 120,
                divisions: 120,
                onChanged: (value) => _emit(_draft.copyWith(tenureMonths: value.round())),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: _daysController,
                      style: AppTypography.inputText,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      decoration: const InputDecoration(hintText: '0', isDense: true),
                      onChanged: (value) => _emit(_draft.copyWith(tenureDays: int.tryParse(value) ?? 0)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // A plain label rather than the field's own prefix/suffix
                  // text, which Flutter hides until the field has focus.
                  Text('extra days', style: AppTypography.fieldLabel),
                  const Spacer(),
                  Text(describeTenure(_draft.tenureMonths, _draft.tenureDays), style: AppTypography.tenureValue),
                ],
              ),
              if (!_draft.hasValidTenure)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Banks accept FDs of 7 days or longer', style: AppTypography.dateLine),
                ),
            ],
          ),
        ),
        FixedwiseFieldShell(
          // For a non-cumulative FD this same choice is how often interest
          // is paid out rather than how often it compounds.
          label: _draft.payoutType == PayoutType.payout ? 'Interest paid' : 'Compounding',
          child: FixedwiseSegmentedControl<CompoundingFrequency>(
            options: CompoundingFrequency.values,
            labelBuilder: (value) => value.label,
            value: _draft.compounding,
            onChanged: (value) => _emit(_draft.copyWith(compounding: value)),
          ),
        ),
        FixedwiseFieldShell(
          label: 'Payout type',
          child: FixedwiseSegmentedControl<PayoutType>(
            options: PayoutType.values,
            labelBuilder: (value) => value.label,
            value: _draft.payoutType,
            onChanged: (value) => _emit(_draft.copyWith(payoutType: value)),
          ),
        ),
      ],
    );
  }
}
