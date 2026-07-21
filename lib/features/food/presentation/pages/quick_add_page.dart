import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/presentation/cubit/quick_add_cubit.dart';

/// The Quick-Add sheet (docs/05 §5.2): opens on recents/favorites so logging
/// is a single tap + confirm — the < 10 s promise (FR-10). Search and a
/// quantity stepper cover the rest without a keyboard where possible.
class QuickAddPage extends StatelessWidget {
  /// Creates the page over an existing [QuickAddCubit].
  const QuickAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuickAddCubit, QuickAddState>(
      listenWhen: (prev, next) => next.justLogged != null,
      listener: (context, state) {
        final entry = state.justLogged!;
        context.read<QuickAddCubit>().acknowledgeLogged();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Added ${entry.item.name} to ${entry.mealSlot.name}',
              ),
            ),
          );
        Navigator.of(context).maybePop(entry);
      },
      builder: (context, state) {
        final cubit = context.read<QuickAddCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Add food')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: SearchBar(
                  hintText: 'Search foods',
                  leading: const Icon(Icons.search),
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _list(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context, QuickAddState state) {
    final searching = state.query.trim().isNotEmpty;
    if (searching) {
      if (state.searchResults.isEmpty) {
        return const _Empty(text: 'No matches. You can add a custom food.');
      }
      return _FoodList(items: state.searchResults);
    }

    final sections = <Widget>[
      if (state.favorites.isNotEmpty) ...[
        const _SectionHeader('Favorites'),
        _FoodList(items: state.favorites, shrink: true),
      ],
      const _SectionHeader('Recents'),
      if (state.recents.isEmpty)
        const _Empty(text: 'Log a food and it will show up here for one tap.')
      else
        _FoodList(items: state.recents, shrink: true),
    ];
    return ListView(children: sections);
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({required this.items, this.shrink = false});

  final List<FoodItem> items;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          key: ValueKey(item.id),
          title: Text(item.name),
          subtitle: Text(
            '${item.nutrition.calories.round()} kcal · '
            '${item.nutrition.proteinG.round()} g protein · '
            'per ${item.servingSize.round()} ${item.servingUnit}',
          ),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () => context.read<QuickAddCubit>().logFood(item),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space6),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
