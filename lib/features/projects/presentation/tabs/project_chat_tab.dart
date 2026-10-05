import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/chat_room_page.dart';
import '../../data/project_models.dart';

final projectConversationProvider = FutureProvider.autoDispose.family<ConversationModel, int>((ref, projectId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getProjectConversation(projectId);
});

class ProjectChatTab extends ConsumerWidget {
  const ProjectChatTab({super.key, required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convAsync = ref.watch(projectConversationProvider(project.id));

    return convAsync.when(
      data: (conv) => Stack(
        children: [
          ChatRoomPage(conversationId: conv.id),
          Positioned(
            top: 12,
            right: 12,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in Fullscreen', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => context.push('/chat/${conv.id}'),
            ),
          ),
        ],
      ),
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Connecting to project channel...'),
          ],
        ),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
            const SizedBox(height: 8),
            Text('Failed to join discussion: $err', style: const TextStyle(color: AppColors.rose)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(projectConversationProvider(project.id)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
