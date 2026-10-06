import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';
import '../application/presence_controller.dart';
import '../../auth/application/auth_controller.dart';
import 'widgets/new_direct_chat_dialog.dart';
import 'widgets/new_group_chat_dialog.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _searchController = TextEditingController();
  String _searchScope = 'chats'; // 'chats' or 'messages'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start a Conversation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                title: const Text('Direct Message'),
                subtitle: const Text('Chat 1-on-1 with an employee'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const NewDirectChatDialog(),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.emerald,
                  child: Icon(Icons.group, color: Colors.white, size: 20),
                ),
                title: const Text('New Group Channel'),
                subtitle: const Text('Create a team or topic chat group'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const NewGroupChatDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsListProvider);
    final filter = ref.watch(conversationsFilterProvider);
    final unreadCountAsync = ref.watch(chatUnreadCountProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: isDesktop ? 20 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Internal Chat',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    unreadCountAsync.when(
                      data: (count) => count > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.rose,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count new',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(isDesktop ? 'New Conversation' : 'New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showNewChatMenu(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                 // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _searchScope == 'messages'
                              ? 'Search message content across all chats...'
                              : 'Search chats, people, projects...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(conversationsFilterProvider.notifier).state =
                                        filter.copyWith(search: '');
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {});
                          ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(search: val.trim());
                        },
                        onSubmitted: (val) {
                          setState(() {});
                          ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(search: val.trim());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Scope Pills (when search query is present)
                if (_searchController.text.trim().isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Search in:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Conversations',
                        icon: Icons.chat_bubble_outline,
                        isSelected: _searchScope == 'chats',
                        onTap: () => setState(() => _searchScope = 'chats'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Message Content',
                        icon: Icons.search,
                        isSelected: _searchScope == 'messages',
                        onTap: () => setState(() => _searchScope = 'messages'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Filter Pills: All, Direct, Group, Project (visible in chats mode)
                if (_searchScope != 'messages' || _searchController.text.trim().isEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Chats',
                          isSelected: filter.type == 'all',
                          onTap: () => ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(type: 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Direct',
                          icon: Icons.person_outline,
                          isSelected: filter.type == 'direct',
                          onTap: () => ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(type: 'direct'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Groups',
                          icon: Icons.group_outlined,
                          isSelected: filter.type == 'group',
                          onTap: () => ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(type: 'group'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Projects',
                          icon: Icons.folder_outlined,
                          isSelected: filter.type == 'project',
                          onTap: () => ref.read(conversationsFilterProvider.notifier).state =
                              filter.copyWith(type: 'project'),
                        ),
                      ],
                    ),
                  ),
                if (_searchScope != 'messages' || _searchController.text.trim().isEmpty)
                  const SizedBox(height: 16),

                // Content View: Messages Search vs Conversations List
                Expanded(
                  child: (_searchScope == 'messages' && _searchController.text.trim().isNotEmpty)
                      ? _MessageSearchResultsView(query: _searchController.text.trim())
                      : conversationsAsync.when(
                    data: (conversations) {
                      if (conversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                filter.search.isNotEmpty
                                    ? 'No conversations matching "${filter.search}"'
                                    : 'No conversations yet',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start a 1-on-1 direct message or create a group to begin chatting.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Start Chat'),
                                onPressed: () => _showNewChatMenu(context),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => ref.refresh(conversationsListProvider),
                        child: ListView.separated(
                          itemCount: conversations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            return _ConversationCard(conversation: conv);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Failed to load conversations: $err', style: TextStyle(color: AppColors.rose)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(conversationsListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  const _ConversationCard({required this.conversation});

  final ConversationModel conversation;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;
    final currentUser = ref.watch(authControllerProvider).value;
    final presence = ref.watch(presenceProvider);

    final partnerId = conversation.partnerId ??
        (conversation.participants.where((p) => p.userId != currentUser?.id).firstOrNull?.userId);
    final isPartnerOnline = conversation.isDirect && partnerId != null
        ? (presence.isUserOnline(partnerId) || conversation.partnerIsOnline == true)
        : false;

    IconData typeIcon;
    Color typeColor;

    if (conversation.isDirect) {
      typeIcon = Icons.person;
      typeColor = AppColors.primary;
    } else if (conversation.isGroup) {
      typeIcon = Icons.group;
      typeColor = AppColors.emerald;
    } else {
      typeIcon = Icons.folder_special;
      typeColor = AppColors.amber;
    }

    String lastMessageSnippet = 'No messages yet';
    final latest = conversation.latestMessage;
    if (latest != null) {
      if (latest.type == 'file' || latest.hasAttachments) {
        lastMessageSnippet = '📎 [Attachment] ${latest.message ?? ''}'.trim();
      } else {
        lastMessageSnippet = latest.message ?? '';
      }
      if (!conversation.isDirect && latest.userName.isNotEmpty) {
        lastMessageSnippet = '${latest.userName.split(' ').first}: $lastMessageSnippet';
      }
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: hasUnread ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
      ),
      color: hasUnread ? AppColors.primary.withValues(alpha: 0.04) : theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: typeColor.withValues(alpha: 0.15),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            if (conversation.isDirect)
              Positioned(
                right: 0,
                bottom: 0,
                child: Tooltip(
                  message: isPartnerOnline ? 'Online' : 'Offline',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isPartnerOnline ? AppColors.emerald : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                conversation.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (conversation.isProject && conversation.projectCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  conversation.projectCode!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber),
                ),
              ),
            const Spacer(),
            Text(
              _formatTime(conversation.lastMessageAt ?? conversation.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? AppColors.primary : AppColors.textMuted,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lastMessageSnippet,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () => context.push('/chat/${conversation.id}'),
      ),
    );
  }
}

class _MessageSearchResultsView extends ConsumerWidget {
  const _MessageSearchResultsView({required this.query});

  final String query;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Type at least 2 characters to search across all messages',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final searchAsync = ref.watch(messageSearchResultsProvider(query));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search failed: $err', style: const TextStyle(color: AppColors.rose)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(messageSearchResultsProvider(query)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 54, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'No messages matching "$query"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try searching for a different word or phrase.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Found ${messages.length} message${messages.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border),
                    ),
                    color: Theme.of(context).cardColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          msg.userName.isNotEmpty ? msg.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              msg.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (msg.userRole != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${msg.userRole})',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _formatTime(msg.createdAt),
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            msg.message ?? (msg.hasAttachments ? '📎 [Attachment]' : ''),
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (msg.hasTaskLink) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Task: ${msg.taskTitle ?? "#${msg.taskId}"}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                      onTap: () => context.push('/chat/${msg.conversationId}'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

