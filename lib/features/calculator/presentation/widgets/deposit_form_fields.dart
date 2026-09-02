import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../../core/widgets/fixedwise_segmented_control.dart';
import '../../../deposits/domain/compounding_frequency.dart';
import '../../../deposits/domain/draft_deposit.dart';
import '../../../deposits/domain/payout_type.dart';

/// The fields shared by the standalone Calculator tab and the New Deposit
/// form: Bank, Interest rate, Principal, Tenure, Compounding, Payout type.
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

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _bankController = TextEditingController(text: _draft.bankName);
    _rateController = TextEditingController(text: _formatRate(_draft.interestRatePercent));
    _principalController = TextEditingController(text: _formatAmount(_draft.principalAmount));
  }

  @override
  void dispose() {
    _bankController.dispose();
    _rateController.dispose();
    _principalController.dispose();
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
              Slider(
                value: _draft.tenureMonths.toDouble().clamp(3, 60),
                min: 3,
                max: 60,
                divisions: 57,
                onChanged: (value) => _emit(_draft.copyWith(tenureMonths: value.round())),
              ),
              Text('${_draft.tenureMonths} months', style: AppTypography.tenureValue),
            ],
          ),
        ),
        FixedwiseFieldShell(
          label: 'Compounding',
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
