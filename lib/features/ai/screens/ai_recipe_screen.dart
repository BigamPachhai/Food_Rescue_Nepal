import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/mistral_service.dart';

final _recipeStateProvider = StateNotifierProvider.autoDispose<_RecipeNotifier, _RecipeState>(
  (ref) => _RecipeNotifier(ref.read(mistralServiceProvider)),
);

class _RecipeState {
  final List<String> ingredients;
  final String? result;
  final bool isLoading;
  const _RecipeState({this.ingredients = const [], this.result, this.isLoading = false});
  _RecipeState copyWith({List<String>? ingredients, String? result, bool? isLoading}) =>
      _RecipeState(
        ingredients: ingredients ?? this.ingredients,
        result: result ?? this.result,
        isLoading: isLoading ?? this.isLoading,
      );
}

class _RecipeNotifier extends StateNotifier<_RecipeState> {
  final MistralService _service;
  _RecipeNotifier(this._service) : super(const _RecipeState());

  void addIngredient(String item) {
    if (item.trim().isEmpty) return;
    state = state.copyWith(ingredients: [...state.ingredients, item.trim()]);
  }

  void removeIngredient(int index) {
    final list = [...state.ingredients]..removeAt(index);
    state = state.copyWith(ingredients: list);
  }

  Future<void> getSuggestions() async {
    if (state.ingredients.isEmpty) return;
    state = state.copyWith(isLoading: true, result: null);
    final result = await _service.suggestRecipes(state.ingredients);
    state = state.copyWith(isLoading: false, result: result);
  }
}

class AiRecipeScreen extends ConsumerStatefulWidget {
  const AiRecipeScreen({super.key});

  @override
  ConsumerState<AiRecipeScreen> createState() => _AiRecipeScreenState();
}

class _AiRecipeScreenState extends ConsumerState<AiRecipeScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_recipeStateProvider);
    final notifier = ref.read(_recipeStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Recipe Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('How it works'),
                content: const Text('Add the rescued food items you have, then tap "Get Recipes" to get AI-powered recipe suggestions using Mistral AI.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildIngredientInput(notifier),
          if (state.ingredients.isNotEmpty) _buildIngredientChips(state, notifier),
          Expanded(child: _buildResult(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildIngredientInput(_RecipeNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add rescued food items you have:', style: AppTextStyles.h6),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. bread, eggs, vegetables...',
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (v) { notifier.addIngredient(v); _ctrl.clear(); },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () { notifier.addIngredient(_ctrl.text); _ctrl.clear(); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChips(_RecipeState state, _RecipeNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: state.ingredients.asMap().entries.map((e) => Chip(
          label: Text(e.value),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => notifier.removeIngredient(e.key),
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
        )).toList(),
      ),
    );
  }

  Widget _buildResult(_RecipeState state, _RecipeNotifier notifier) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryMedium),
            const SizedBox(height: 16),
            Text('Getting recipe ideas...', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    if (state.result != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded, color: AppColors.primaryMedium),
                const SizedBox(width: 8),
                Text('Recipe Suggestions', style: AppTextStyles.h5),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Text(state.result!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: notifier.getSuggestions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Get More Ideas'),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text('Add your rescued food items above', style: AppTextStyles.h5, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Then get creative recipe ideas from AI!', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (state.ingredients.isNotEmpty)
              ElevatedButton.icon(
                onPressed: notifier.getSuggestions,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Get Recipes'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
