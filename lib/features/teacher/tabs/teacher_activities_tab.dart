import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class TeacherActivitiesTab extends ConsumerStatefulWidget {
  const TeacherActivitiesTab({super.key});

  @override
  ConsumerState<TeacherActivitiesTab> createState() => _TeacherActivitiesTabState();
}

class _TeacherActivitiesTabState extends ConsumerState<TeacherActivitiesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateNoticeModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    ActivityCategory selectedCategory = ActivityCategory.notice;
    CircularPriority selectedPriority = CircularPriority.normal;
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 2));
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Publish Official Notice',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official circulars appear highlighted on student dashboards.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    controller: titleCtrl,
                    labelText: 'Notice Title',
                    hintText: 'e.g. End Semester Practical Schedule',
                    prefixIcon: Icons.campaign_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ActivityCategory>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: ActivityCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat.label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<CircularPriority>(
                          initialValue: selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                          items: CircularPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPriority = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: descCtrl,
                    labelText: 'Notice Description & Details',
                    hintText: 'Full content of the academic notice or guidelines...',
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: locationCtrl,
                    labelText: 'Venue / Meeting Link',
                    hintText: 'e.g. Lab 4 or Google Meet',
                    prefixIcon: Icons.place_outlined,
                  ),
                  const SizedBox(height: 24),

                  AppButton.primary(
                    label: 'Publish Official Announcement',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);

                      final teacher = ref.read(teacherProfileProvider);
                      final firestoreService = ref.read(firestoreServiceProvider);
                      final now = DateTime.now();

                      final post = ActivityPostModel(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: selectedCategory,
                        authorId: teacher?.user.id ?? 'faculty',
                        authorName: teacher?.user.name ?? 'Faculty Member',
                        authorRole: 'teacher',
                        isOfficial: true,
                        status: ActivityStatus.approved,
                        eventDate: selectedDate,
                        location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                        organizer: teacher?.user.department ?? 'Academic Faculty',
                        createdAt: now,
                        updatedAt: now,
                      );

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      await firestoreService.saveActivityPost(post);

                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Official notice published successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final activities = activitiesAsync.valueOrNull ?? [];
    final pendingAsync = ref.watch(pendingActivitiesStreamProvider);
    final pending = pendingAsync.valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateNoticeModal(context),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Create Notice'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Official Feed'),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: activities.length.toString(),
                      color: AppColors.primary,
                      small: true,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Review Pending'),
                    if (pending.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: pending.length.toString(),
                        color: AppColors.warning,
                        small: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Published Official Feed
                activities.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.campaign_outlined,
                        title: 'No Notices Published',
                        subtitle: 'Tap Create Notice to broadcast an official announcement.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                        itemCount: activities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final post = activities[index];
                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CategoryBadge(category: post.category, small: true),
                                    const Spacer(),
                                    if (post.isOfficial)
                                      const StatusBadge(
                                        label: 'Official',
                                        color: AppColors.primary,
                                        icon: Icons.verified_outlined,
                                        small: true,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  post.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'By ${post.authorName} (${post.authorRole})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('d MMM, yyyy').format(post.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // Tab 1: Pending Student Submissions
                pending.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.done_all_rounded,
                        title: 'All Clear!',
                        subtitle: 'No student activity submissions currently pending review.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                        itemCount: pending.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final post = pending[index];
                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CategoryBadge(category: post.category, small: true),
                                    const Spacer(),
                                    const StatusBadge(
                                      label: 'Pending Approval',
                                      color: AppColors.warning,
                                      small: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  post.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Submitted by ${post.authorName} • ${DateFormat('d MMM, hh:mm a').format(post.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        ref.read(firestoreServiceProvider).rejectActivityPost(post.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Submission rejected.')),
                                        );
                                      },
                                      child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(firestoreServiceProvider).approveActivityPost(post.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Activity post approved & published!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      },
                                      child: const Text('Approve & Publish'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
