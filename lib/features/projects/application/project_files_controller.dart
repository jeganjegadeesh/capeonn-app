import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/chat_models.dart';
import '../data/project_files_repository.dart';

class ProjectFilesCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final projectFilesCategoryProvider =
    NotifierProvider.family<ProjectFilesCategoryNotifier, String, int>((projectId) {
  return ProjectFilesCategoryNotifier();
});

class ProjectFilesSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final projectFilesSearchProvider =
    NotifierProvider.family<ProjectFilesSearchNotifier, String, int>((projectId) {
  return ProjectFilesSearchNotifier();
});

final projectFilesProvider = FutureProvider.family<List<ProjectFileModel>, int>((ref, projectId) async {
  final repo = ref.watch(projectFilesRepositoryProvider);
  final category = ref.watch(projectFilesCategoryProvider(projectId));
  final search = ref.watch(projectFilesSearchProvider(projectId));

  return repo.getProjectFiles(
    projectId,
    category: category != 'all' ? category : null,
    search: search.isNotEmpty ? search : null,
  );
});
