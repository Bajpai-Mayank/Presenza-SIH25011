import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:share_plus/share_plus.dart';

class AdminCircularsTab extends ConsumerStatefulWidget {
  const AdminCircularsTab({super.key});

  @override
  ConsumerState<AdminCircularsTab> createState() => _AdminCircularsTabState();
}

class _AdminCircularsTabState extends ConsumerState<AdminCircularsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCircularModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCoursesCtrl = TextEditingController();
    final targetBatchesCtrl = TextEditingController();
    final targetSemestersCtrl = TextEditingController();
    CircularPriority selectedPriority = CircularPriority.important;
    ActivityCategory selectedCategory = ActivityCategory.notice;
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Broadcast Official Notice',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administrative notices are instantly sent across all campus dashboards.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    controller: titleCtrl,
                    labelText: 'Notice Title',
                    hintText: 'e.g. Campus Holiday Declaration or Exam Circular',
                    prefixIcon: Icons.campaign_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      final catField = DropdownButtonFormField<ActivityCategory>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: ActivityCategory.values.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat.label, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategory = val);
                        },
                      );
                      final priorityField = DropdownButtonFormField<CircularPriority>(
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: CircularPriority.values.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p.displayName, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPriority = val);
                        },
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            catField,
                            const SizedBox(height: 12),
                            priorityField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: catField),
                          const SizedBox(width: 12),
                          Expanded(child: priorityField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: descCtrl,
                    labelText: 'Circular Content & Instructions',
                    hintText: 'Provide complete details for students and staff...',
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  
                  Text(
                    'Target Audience (Optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  AppTextField(
                    controller: targetCoursesCtrl,
                    labelText: 'Target Course IDs (comma-separated)',
                    hintText: 'e.g. course-btech-cse, course-mtech (or leave blank)',
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 10),

                  AppTextField(
                    controller: targetBatchesCtrl,
                    labelText: 'Target Batch IDs (comma-separated)',
                    hintText: 'e.g. batch-2024-a, batch-2024-b',
                    prefixIcon: Icons.group_outlined,
                  ),
                  const SizedBox(height: 10),

                  AppTextField(
                    controller: targetSemestersCtrl,
                    labelText: 'Target Semesters (comma-separated)',
                    hintText: 'e.g. 1, 2, 4',
                    prefixIcon: Icons.format_list_numbered_rounded,
                  ),
                  const SizedBox(height: 24),

                  AppButton.primary(
                    label: 'Publish & Broadcast',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);

                      final user = ref.read(currentUserProvider);
                      final firestoreService = ref.read(firestoreServiceProvider);
                      final now = DateTime.now();
                      
                      final courseIds = targetCoursesCtrl.text.isNotEmpty 
                          ? targetCoursesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
                          : <String>[];
                      final batchIds = targetBatchesCtrl.text.isNotEmpty 
                          ? targetBatchesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
                          : <String>[];
                      final semesters = targetSemestersCtrl.text.isNotEmpty 
                          ? targetSemestersCtrl.text.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList() 
                          : <int>[];

                      final post = ActivityPostModel(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: selectedCategory,
                        authorId: user?.id ?? 'admin',
                        authorName: user?.name ?? 'Campus Administration',
                        authorRole: 'admin',
                        isOfficial: true,
                        status: ActivityStatus.approved,
                        organizer: 'Office of Campus Administration',
                        targetCourseIds: courseIds,
                        targetBatchIds: batchIds,
                        targetSemesters: semesters,
                        createdAt: now,
                        updatedAt: now,
                      );

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      try {
                        await firestoreService.saveActivityPost(post);

                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Notice published and broadcast across campus!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to publish circular: $e'),
                            backgroundColor: AppColors.error,
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

  void _confirmDeletePost(BuildContext context, String postId) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice?'),
        content: const Text('Are you sure you want to delete this notice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(firestoreServiceProvider).deleteActivityPost(postId);
              messenger.showSnackBar(
                const SnackBar(content: Text('Notice deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final activities = activitiesAsync.valueOrNull ?? [];
    final pendingAsync = ref.watch(pendingActivitiesStreamProvider);
    final pendingActivities = pendingAsync.valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = activities.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.toLowerCase().contains(_searchQuery) ||
          a.description.toLowerCase().contains(_searchQuery) ||
          a.authorName.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateCircularModal(context),
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('New Notice'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Quick Broadcast Notice Banner (Admin)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: InkWell(
              onTap: () => _showCreateCircularModal(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF7C3AED).withAlpha(25),
                      child: const Icon(Icons.campaign_rounded, size: 16, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Broadcast institutional circular or official notice...',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search all notices...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: '📢 Official Circulars'),
              const Tab(text: 'All Campus Feed'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⏳ Pending Approvals'),
                    if (pendingActivities.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: pendingActivities.length.toString(),
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
                _buildNoticeList(
                  filteredList.where((a) => a.isOfficial).toList(),
                  isDark,
                  emptyTitle: 'No Official Circulars',
                  emptySubtitle: 'Tap New Notice to publish an administrative broadcast.',
                ),
                _buildNoticeList(
                  filteredList,
                  isDark,
                  emptyTitle: 'No Campus Feed Found',
                  emptySubtitle: 'Notices and activities published across campus will appear here.',
                ),
                _buildAdminPendingList(pendingActivities, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPendingList(List<ActivityPostModel> list, bool isDark) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.task_alt_rounded,
        title: 'No Pending Notices',
        subtitle: 'All campus and student notice submissions have been moderated.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notice = list[index];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryBadge(category: notice.category, small: true),
                  const SizedBox(width: 8),
                  const StatusBadge(
                    label: 'Pending Approval',
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                    small: true,
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM yyyy, hh:mm a').format(notice.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notice.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted by ${notice.authorName} (${notice.authorRole})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(firestoreServiceProvider).rejectActivityPost(notice.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notice rejected.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                    label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(firestoreServiceProvider).approveActivityPost(notice.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notice approved and broadcasted across campus!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('Approve & Broadcast', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeList(
    List<ActivityPostModel> list,
    bool isDark, {
    String emptyTitle = 'No Notices Published',
    String emptySubtitle = 'Tap New Notice to publish an administrative broadcast.',
  }) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.campaign_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notice = list[index];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryBadge(category: notice.category, small: true),
                  const SizedBox(width: 8),
                  if (notice.isOfficial)
                    const StatusBadge(
                      label: 'Official',
                      color: AppColors.primary,
                      icon: Icons.verified_outlined,
                      small: true,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    tooltip: 'Delete Notice',
                    onPressed: () => _confirmDeletePost(context, notice.id),
                  ),
                  Text(
                    DateFormat('d MMM yyyy').format(notice.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notice.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Posted by ${notice.authorName} (${notice.authorRole})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Share Notice',
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: '📢 Official Administration Circular: ${notice.title}\n\n${notice.description}\n\nPublished: ${DateFormat('d MMM yyyy').format(notice.createdAt)}\nPresenza Campus Portal',
                          subject: notice.title,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
