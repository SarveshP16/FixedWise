import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../deposits/application/fixed_deposits_providers.dart';
import '../../../deposits/domain/draft_deposit.dart';
import '../widgets/calc_output_panel.dart';
import '../widgets/deposit_form_fields.dart';

/// FixedWise's Calculator tab: a pure "what would this FD earn" tool with
/// no persistence — the mockup's New Deposit screen's form and live
/// calculator, reused here without the Holder/Auto-renew/Create-deposit
/// bits that only make sense once you're actually saving a record.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  DraftDeposit _draft = DraftDeposit.initial();

  @override
  Widget build(BuildContext context) {
    final bankSuggestions = ref.watch(fixedDepositRepositoryProvider).distinctBankNames();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Text('Calculator', style: AppTypography.screenTitle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: DepositFormFields(
                  initial: _draft,
                  bankSuggestions: bankSuggestions,
                  currencySymbol: currencySymbol,
                  onChanged: (draft) => setState(() => _draft = draft),
                ),
              ),
              const SizedBox(height: 4),
              CalcOutputPanel(draft: _draft),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
