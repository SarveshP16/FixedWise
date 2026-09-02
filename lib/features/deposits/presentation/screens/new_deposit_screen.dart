import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/maturity_reminder_sync.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../../../../core/widgets/cta_button.dart';
import '../../../../core/widgets/fixedwise_field_shell.dart';
import '../../../calculator/presentation/widgets/calc_output_panel.dart';
import '../../../calculator/presentation/widgets/deposit_form_fields.dart';
import '../../../holders/application/holders_providers.dart';
import '../../../profile/application/settings_providers.dart';
import '../../application/fixed_deposits_providers.dart';
import '../../domain/draft_deposit.dart';
import '../../domain/fd_status.dart';
import '../../domain/fixed_deposit.dart';

/// FixedWise's New Deposit form (the mockup's "New deposit, live
/// calculator" screen) — the same shared [DepositFormFields] as the
/// Calculator tab, plus Holder/Auto-renew/FD-number fields the mockup
/// doesn't depict, and a CTA that actually persists the record.
class NewDepositScreen extends ConsumerStatefulWidget {
  const NewDepositScreen({super.key});

  @override
  ConsumerState<NewDepositScreen> createState() => _NewDepositScreenState();
}

class _NewDepositScreenState extends ConsumerState<NewDepositScreen> {
  DraftDeposit _draft = DraftDeposit.initial();
  String? _holderId;
  bool _autoRenew = false;
  DateTime _openedDate = DateTime.now();
  final _fdNumberController = TextEditingController();

  @override
  void dispose() {
    _fdNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankSuggestions = ref.watch(fixedDepositRepositoryProvider).distinctBankNames();
    final currencySymbol = ref.watch(currencySymbolProvider);
    final holders = ref.watch(holdersProvider);
    final selfHolder = ref.watch(selfHolderProvider);
    _holderId ??= selfHolder?.id;

    final canCreate = _draft.bankName.trim().isNotEmpty && _draft.principalAmount > 0 && _draft.tenureMonths > 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Row(
                  children: [
                    BorderedIconButton(icon: Icons.close, size: 32, onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Text('New deposit', style: AppTypography.detailTitle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DepositFormFields(
                      initial: _draft,
                      bankSuggestions: bankSuggestions,
                      currencySymbol: currencySymbol,
                      onChanged: (draft) => setState(() => _draft = draft),
                    ),
                    FixedwiseFieldShell(
                      label: 'Opened date',
                      child: FixedwiseInputBox(
                        onTap: _pickOpenedDate,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('d MMM yyyy').format(_openedDate), style: AppTypography.inputText),
                            const Icon(Icons.calendar_today_outlined, size: 16),
                          ],
                        ),
                      ),
                    ),
                    if (holders.length > 1)
                      FixedwiseFieldShell(
                        label: 'Holder',
                        child: FixedwiseInputBox(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _holderId,
                              items: [
                                for (final holder in holders)
                                  DropdownMenuItem(value: holder.id, child: Text(holder.name)),
                              ],
                              onChanged: (value) => setState(() => _holderId = value),
                            ),
                          ),
                        ),
                      ),
                    FixedwiseFieldShell(
                      label: 'FD number (optional)',
                      child: FixedwiseInputBox(
                        child: TextField(
                          controller: _fdNumberController,
                          style: AppTypography.inputText,
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        ),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Auto-renew at maturity', style: AppTypography.fieldLabel),
                      value: _autoRenew,
                      onChanged: (value) => setState(() => _autoRenew = value),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              CalcOutputPanel(draft: _draft),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: CtaButton(
                  label: 'Create deposit',
                  onPressed: canCreate && _holderId != null ? () => _create(_holderId!) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickOpenedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedDate,
      // FDs are commonly onboarded well after they were actually opened —
      // allow up to 20 years back — but never a future start date.
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _openedDate = picked);
  }

  Future<void> _create(String holderId) async {
    final now = DateTime.now();
    final deposit = FixedDeposit(
      id: generateId(),
      holderId: holderId,
      bankName: _draft.bankName.trim(),
      interestRatePercent: _draft.interestRatePercent,
      principalAmount: _draft.principalAmount,
      openedDate: _openedDate,
      tenureMonths: _draft.tenureMonths,
      compounding: _draft.compounding,
      payoutType: _draft.payoutType,
      autoRenew: _autoRenew,
      fdNumber: _fdNumberController.text.trim().isEmpty ? null : _fdNumberController.text.trim(),
      status: FdStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(fixedDepositsProvider.notifier).add(deposit);
    await onDepositSaved(deposit, leadDays: ref.read(notificationLeadDaysProvider));
    if (mounted) context.pop();
  }
}
