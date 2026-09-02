import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../data/holder_repository.dart';
import '../domain/holder.dart';

final holderRepositoryProvider = Provider<HolderRepository>((ref) {
  return HolderRepository.openDefault();
});

/// The live list of holders, oldest (Self) first. UI reads this provider;
/// mutations go through its notifier's methods so every screen stays in
/// sync automatically.
final holdersProvider = StateNotifierProvider<HoldersNotifier, List<Holder>>((ref) {
  return HoldersNotifier(ref.watch(holderRepositoryProvider));
});

class HoldersNotifier extends StateNotifier<List<Holder>> {
  HoldersNotifier(this._repository) : super(_repository.getAll()) {
    _seedSelfIfNeeded();
  }

  final HolderRepository _repository;

  Future<void> _seedSelfIfNeeded() async {
    if (state.any((holder) => holder.isSelf)) return;
    await _repository.ensureSelfHolder();
    state = _repository.getAll();
  }

  Future<void> add(String name) async {
    final holder = Holder(id: generateId(), name: name, isSelf: false, createdAt: DateTime.now());
    await _repository.add(holder);
    state = _repository.getAll();
  }

  Future<void> rename(String id, String name) async {
    final holder = state.firstWhere((h) => h.id == id);
    await _repository.update(holder.copyWith(name: name));
    state = _repository.getAll();
  }

  /// Callers must check `!holder.isSelf` and that no FD still references
  /// this holder before calling this — see `holders_screen.dart`'s delete
  /// confirmation, which does both.
  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}

/// The Self holder — always present after `HoldersNotifier`'s first build.
/// Used as the default holder for a brand-new FD.
final selfHolderProvider = Provider<Holder?>((ref) {
  final holders = ref.watch(holdersProvider);
  for (final holder in holders) {
    if (holder.isSelf) return holder;
  }
  return null;
});
