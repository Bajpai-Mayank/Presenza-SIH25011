import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class StudentActivitiesTab extends ConsumerStatefulWidget {
  const StudentActivitiesTab({super.key});

  @override
  ConsumerState<StudentActivitiesTab> createState() => _StudentActivitiesTabState();
}

class _StudentActivitiesTabState extends ConsumerState<StudentActivitiesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  ActivityCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  void _showCreatePostDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final organizerCtrl = TextEditingController();
    ActivityCategory selectedCategory = ActivityCategory.workshop;
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 3));
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
                        'Submit Activity / Event',
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
                    'Student posts are reviewed and approved by faculty before going live.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    controller: titleCtrl,
                    labelText: 'Activity Title',
                    hintText: 'e.g. AI & Robotics Hackathon 2025',
                    prefixIcon: Icons.title_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<ActivityCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: ActivityCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16, color: cat.color),
                            const SizedBox(width: 8),
                            Text(cat.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: descCtrl,
                    labelText: 'Description & Details',
                    hintText: 'Provide event details, schedule, requirements, and registration links...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: locationCtrl,
                    labelText: 'Location / Venue',
                    hintText: 'e.g. Auditorium Hall A or Online Meet',
                    prefixIcon: Icons.place_outlined,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: organizerCtrl,
                    labelText: 'Organizer / Club Name',
                    hintText: 'e.g. IEEE Student Branch',
                    prefixIcon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 24),

                  AppButton.primary(
                    label: 'Submit for Approval',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);

                      final student = ref.read(studentProfileProvider);
                      final firestoreService = ref.read(firestoreServiceProvider);
                      final now = DateTime.now();

                      final post = ActivityPostModel(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: selectedCategory,
                        authorId: student?.user.id ?? 'student',
                        authorName: student?.user.name ?? 'Student Author',
                        authorRole: 'student',
                        isOfficial: false,
                        status: ActivityStatus.pending,
                        eventDate: selectedDate,
                        location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                        organizer: organizerCtrl.text.trim().isNotEmpty ? organizerCtrl.text.trim() : null,
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
                            content: Text('Activity submitted! It will appear once approved by faculty.'),
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
    final student = ref.read(studentProfileProvider);
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
                  Column(
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
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
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
                      subtitle: 'Be the first to join the conversation!',
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
                      hintText: 'Write a comment...',
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
                        authorId: student?.user.id ?? 'student',
                        authorName: student?.user.name ?? 'Student',
                        authorRole: 'student',
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

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final activities = activitiesAsync.valueOrNull ?? [];
    final student = ref.watch(studentProfileProvider);
    final uid = student?.user.id ?? '';
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
        onPressed: () => _showCreatePostDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Activity'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search campus activities, notices, workshops...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),

          // Categories Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Categories'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...ActivityCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(cat.icon, size: 14),
                      label: Text(cat.label),
                      selected: _selectedCategory == cat,
                      onSelected: (val) {
                        setState(() => _selectedCategory = val ? cat : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Sub Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'All Feed'),
              Tab(text: 'Official Circulars'),
              Tab(text: 'Student Events'),
              Tab(text: 'Bookmarked'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(filteredList, uid, isDark),
                _buildActivityList(
                  filteredList.where((a) => a.isOfficial).toList(),
                  uid,
                  isDark,
                ),
                _buildActivityList(
                  filteredList.where((a) => !a.isOfficial).toList(),
                  uid,
                  isDark,
                ),
                _buildActivityList(
                  filteredList.where((a) => a.isBookmarked(uid)).toList(),
                  uid,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<ActivityPostModel> list, String uid, bool isDark) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.campaign_outlined,
        title: 'No Activities Found',
        subtitle: 'No campus announcements match your current filter criteria.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final post = list[index];
        final isInterested = post.isInterested(uid);
        final isBookmarked = post.isBookmarked(uid);
        final userReaction = post.getUserReaction(uid);

        return AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category & Official Badge Row
              Row(
                children: [
                  CategoryBadge(category: post.category),
                  const SizedBox(width: 8),
                  if (post.isOfficial)
                    const StatusBadge(
                      label: 'Official',
                      color: AppColors.primary,
                      icon: Icons.verified_outlined,
                      small: true,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 22,
                      color: isBookmarked ? AppColors.primary : null,
                    ),
                    onPressed: () {
                      if (uid.isNotEmpty) {
                        ref.read(firestoreServiceProvider).togglePostBookmark(
                              postId: post.id,
                              userId: uid,
                            );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                post.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Event details (Date & Location)
              if (post.eventDate != null || post.location != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (post.eventDate != null) ...[
                        const Icon(Icons.event_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('d MMM yyyy, hh:mm a').format(post.eventDate!),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (post.location != null) ...[
                        const Icon(Icons.place_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.location!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Author & Published time
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${post.authorName} (${post.authorRole})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM').format(post.createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Interaction Row: Reactions, Comments, Interested
              Row(
                children: [
                  // Like Reaction
                  _ReactionButton(
                    icon: Icons.thumb_up_alt_outlined,
                    activeIcon: Icons.thumb_up_alt_rounded,
                    isActive: userReaction == 'like',
                    count: post.reactionCounts['like'] ?? 0,
                    color: AppColors.primary,
                    onTap: () {
                      if (uid.isNotEmpty) {
                        ref.read(firestoreServiceProvider).toggleReaction(
                              postId: post.id,
                              userId: uid,
                              reactionType: 'like',
                            );
                      }
                    },
                  ),
                  const SizedBox(width: 12),

                  // Fire Reaction
                  _ReactionButton(
                    icon: Icons.local_fire_department_outlined,
                    activeIcon: Icons.local_fire_department_rounded,
                    isActive: userReaction == 'fire',
                    count: post.reactionCounts['fire'] ?? 0,
                    color: const Color(0xFFEA580C),
                    onTap: () {
                      if (uid.isNotEmpty) {
                        ref.read(firestoreServiceProvider).toggleReaction(
                              postId: post.id,
                              userId: uid,
                              reactionType: 'fire',
                            );
                      }
                    },
                  ),
                  const SizedBox(width: 12),

                  // Comments
                  InkWell(
                    onTap: () => _showCommentsModal(context, post),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            post.commentCount.toString(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Going / Interested Button
                  OutlinedButton.icon(
                    onPressed: () {
                      if (uid.isNotEmpty) {
                        ref.read(firestoreServiceProvider).toggleInterested(
                              postId: post.id,
                              userId: uid,
                            );
                      }
                    },
                    icon: Icon(
                      isInterested ? Icons.check_circle_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: isInterested ? AppColors.success : null,
                    ),
                    label: Text(
                      isInterested ? 'Going (${post.interestedUids.length})' : 'Interested',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isInterested ? AppColors.success : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(
                        color: isInterested ? AppColors.success : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                      ),
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

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive ? color : null,
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
