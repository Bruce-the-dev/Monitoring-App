import 'package:flutter/material.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class SearchBar extends StatelessWidget {
  final FloatingSearchBarController controller;
  final Function(String query) onQueryChanged;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      controller: controller,
      hint: 'Search vehicles...',
      transitionDuration: const Duration(milliseconds: 500),
      debounceDelay: const Duration(milliseconds: 300),
      physics: const BouncingScrollPhysics(),
      transition: CircularFloatingSearchBarTransition(),
      onQueryChanged: onQueryChanged,
      builder:
          (context, transition) => const SizedBox.shrink(), // customize later
    );
  }
}
