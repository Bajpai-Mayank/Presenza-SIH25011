import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/activity_model.dart';

/// Modal bottom sheet for filtering campus activities by category & timeline.
class ActivityFilterSheet extends StatefulWidget {
  final ActivityCategory? selectedCategory;
  final String selectedTimeline; // 'all', 'upcoming', 'past'
  final ValueChanged<ActivityCategory?> onCategoryChanged;
  final ValueChanged<String> onTimelineChanged;

  const ActivityFilterSheet({
    super.key,
    this.selectedCategory,
    required this.selectedTimeline,
    required this.onCategoryChanged,
    required this.onTimelineChanged,
  });

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  ActivityCategory? _category;
  late String _timeline;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _timeline = widget.selectedTimeline;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Activities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Events'),
                selected: _timeline == 'all',
                onSelected: (val) => setState(() => _timeline = 'all'),
              ),
              ChoiceChip(
                label: const Text('Upcoming'),
                selected: _timeline == 'upcoming',
                onSelected: (val) => setState(() => _timeline = 'upcoming'),
              ),
              ChoiceChip(
                label: const Text('Past Events'),
                selected: _timeline == 'past',
                onSelected: (val) => setState(() => _timeline = 'past'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Category',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Categories'),
                selected: _category == null,
                onSelected: (val) => setState(() => _category = null),
              ),
              ...ActivityCategory.values.map((cat) {
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16),
                  label: Text(cat.label),
                  selected: _category == cat,
                  onSelected: (val) {
                    setState(() => _category = val ? cat : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onCategoryChanged(null);
                    widget.onTimelineChanged('all');
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onCategoryChanged(_category);
                    widget.onTimelineChanged(_timeline);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
