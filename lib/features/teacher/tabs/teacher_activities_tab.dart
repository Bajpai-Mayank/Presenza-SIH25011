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

class TeacherActivitiesTab extends ConsumerStatefulWidget {
  const TeacherActivitiesTab({super.key});

  @override
  ConsumerState<TeacherActivitiesTab> createState() => _TeacherActivitiesTabState();
}

class _TeacherActivitiesTabState extends ConsumerState<TeacherActivitiesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityCategory? _selectedCategory;

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

  void _showCreateNoticeModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final targetCourseCtrl = TextEditingController();
    final targetBatchCtrl = TextEditingController();
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
                            'Publish Faculty Notice',
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
                    'Broadcast notices, academic updates, and circulars directly to students and faculty.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: titleCtrl,
                    labelText: 'Notice / Announcement Title',
                    hintText: 'e.g. End Semester Practical Exam Schedule',
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
                    labelText: 'Venue / Meeting Link (Optional)',
                    hintText: 'e.g. Lab 4 or Google Meet link',
                    prefixIcon: Icons.place_outlined,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: targetCourseCtrl,
                    labelText: 'Target Course IDs (Optional, comma-separated)',
                    hintText: 'e.g. course-btech-cse (Leave blank for campus-wide)',
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 24),

                  AppButton.primary(
                    label: 'Publish & Broadcast Notice',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);

                      final teacher = ref.read(teacherProfileProvider);
                      final firestoreService = ref.read(firestoreServiceProvider);
                      final now = DateTime.now();

                      final courseIds = targetCourseCtrl.text.isNotEmpty
                          ? targetCourseCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                          : <String>[];
                      final batchIds = targetBatchCtrl.text.isNotEmpty
                          ? targetBatchCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                          : <String>[];

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
                        targetCourseIds: courseIds,
                        targetBatchIds: batchIds,
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
                            content: Text('Notice broadcasted to students and faculty!'),
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

  void _showCommentsModal(BuildContext context, ActivityPostModel post) {
    final commentCtrl = TextEditingController();
    final teacher = ref.read(teacherProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comments & Discussion',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          post.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<ActivityCommentModel>>(
                stream: ref.read(firestoreServiceProvider).streamActivityComments(post.id),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingState();
                  }
                  if (comments.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No Comments Yet',
                      subtitle: 'Start the conversation!',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isDark ? AppColors.elevatedDark : AppColors.slate200,
                                  child: Text(
                                    c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.authorName,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                if (c.authorRole == 'teacher')
                                  const StatusBadge(label: 'Faculty', color: AppColors.primary, small: true),
                                const Spacer(),
                                Text(
                                  DateFormat('d MMM, hh:mm a').format(c.createdAt),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(c.content, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: commentCtrl,
                      hintText: 'Write a response as Faculty...',
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () async {
                      final text = commentCtrl.text.trim();
                      if (text.isEmpty) return;

                      final comment = ActivityCommentModel(
                        id: const Uuid().v4(),
                        activityId: post.id,
                        authorId: teacher?.user.id ?? 'faculty',
                        authorName: teacher?.user.name ?? 'Faculty',
                        authorRole: 'teacher',
                        content: text,
                        createdAt: DateTime.now(),
                      );

                      commentCtrl.clear();
                      await ref.read(firestoreServiceProvider).addActivityComment(comment);
                    },
                  ),
                ],
              ),
            ),
          ],
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
    final teacher = ref.watch(teacherProfileProvider);
    final teacherUid = teacher?.user.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter by search query and category
    List<ActivityPostModel> filteredList = activities.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.toLowerCase().contains(_searchQuery) ||
          a.description.toLowerCase().contains(_searchQuery) ||
          a.authorName.toLowerCase().contains(_searchQuery);
      final matchesCat = _selectedCategory == null || a.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateNoticeModal(context),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('Create Notice'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search notices and activities...',
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
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Campus Feed'),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: activities.length.toString(),
                      color: AppColors.primary,
                      small: true,
                    ),
                  ],
                ),
              ),
              const Tab(
                text: '📢 Official Notices',
              ),
              const Tab(
                text: '👤 My Notices',
              ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: All Campus Feed
                _buildTeacherPostList(filteredList, teacherUid, isDark),

                // Tab 1: Official & Faculty Notices
                _buildTeacherPostList(
                  filteredList.where((a) => a.isOfficial || a.authorRole == 'teacher' || a.authorRole == 'admin').toList(),
                  teacherUid,
                  isDark,
                  emptyTitle: 'No Official Notices',
                  emptySubtitle: 'Publish an official notice to broadcast across campus.',
                ),

                // Tab 2: My Published Notices
                _buildTeacherPostList(
                  filteredList.where((a) => a.authorId == teacherUid).toList(),
                  teacherUid,
                  isDark,
                  emptyTitle: 'You Haven\'t Published Any Notices',
                  emptySubtitle: 'Tap Create Notice to broadcast an announcement to your students.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherPostList(
    List<ActivityPostModel> list,
    String uid,
    bool isDark, {
    String emptyTitle = 'No Notices Found',
    String emptySubtitle = 'Tap Create Notice to broadcast an announcement.',
  }) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.campaign_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final post = list[index];
        final isOwner = post.authorId == uid;
        final userReaction = post.getUserReaction(uid);

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryBadge(category: post.category, small: true),
                  const SizedBox(width: 8),
                  if (post.isOfficial)
                    const StatusBadge(
                      label: 'Official',
                      color: AppColors.primary,
                      icon: Icons.verified_outlined,
                      small: true,
                    ),
                  const Spacer(),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      tooltip: 'Delete Notice',
                      onPressed: () => _confirmDeletePost(context, post.id),
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
              if (post.location != null || post.eventDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (post.eventDate != null) ...[
                      const Icon(Icons.event_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM yyyy, hh:mm a').format(post.eventDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (post.location != null) ...[
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.location!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
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
                  // Reaction
                  IconButton(
                    icon: Icon(
                      userReaction == 'like' ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: userReaction == 'like' ? AppColors.primary : null,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Like',
                    onPressed: () {
                      if (uid.isNotEmpty) {
                        ref.read(firestoreServiceProvider).toggleReaction(
                              postId: post.id,
                              userId: uid,
                              reactionType: 'like',
                            );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  // Comments
                  InkWell(
                    onTap: () => _showCommentsModal(context, post),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            post.commentCount.toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Share
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Share Notice',
                    onPressed: () {
                      final venueStr = post.location != null ? '\n📍 Venue: ${post.location}' : '';
                      final dateStr = post.eventDate != null ? '\n🗓 Date: ${DateFormat('d MMM yyyy, hh:mm a').format(post.eventDate!)}' : '';
                      SharePlus.instance.share(
                        ShareParams(
                          text: '📢 Presenza Notice: ${post.title}\n\n${post.description}$dateStr$venueStr\n\nPublished by ${post.authorName}',
                          subject: post.title,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
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
    );
  }
}
