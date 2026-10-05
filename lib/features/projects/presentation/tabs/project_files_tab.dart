import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../chat/data/chat_models.dart';
import '../../application/project_files_controller.dart';
import '../../data/project_files_repository.dart';
import '../../data/project_models.dart';

class ProjectFilesTab extends ConsumerStatefulWidget {
  const ProjectFilesTab({super.key, required this.project});

  final ProjectItem project;

  @override
  ConsumerState<ProjectFilesTab> createState() => _ProjectFilesTabState();
}

class _ProjectFilesTabState extends ConsumerState<ProjectFilesTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUploadDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'general';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Upload Project File'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'File Name *',
                    hintText: 'e.g. architecture_diagram.png, spec_v1.pdf',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'specification', child: Text('Specification')),
                    DropdownMenuItem(value: 'design', child: Text('Design Assets')),
                    DropdownMenuItem(value: 'document', child: Text('Documentation')),
                    DropdownMenuItem(value: 'report', child: Text('Report')),
                    DropdownMenuItem(value: 'archive', child: Text('Archive / Zip')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Notes or version details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload),
              label: Text(isUploading ? 'Uploading...' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isUploading
                  ? null
                  : () async {
                      final fname = nameController.text.trim();
                      if (fname.isEmpty) {
                        AppToast.error(context, 'Please enter a file name');
                        return;
                      }

                      setDialogState(() => isUploading = true);

                      try {
                        final repo = ref.read(projectFilesRepositoryProvider);
                        final dummyContent = utf8.encode('Capeonn Document: $fname\nProject: ${widget.project.name}');

                        await repo.uploadProjectFile(
                          widget.project.id,
                          fileBytes: dummyContent,
                          fileName: fname,
                          category: category,
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : null,
                        );

                        ref.invalidate(projectFilesProvider(widget.project.id));
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          AppToast.success(context, 'File uploaded successfully');
                        }
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (context.mounted) {
                          AppToast.error(context, 'Upload failed: $e');
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFile(ProjectFileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(projectFilesRepositoryProvider);
        await repo.deleteProjectFile(widget.project.id, file.id);
        ref.invalidate(projectFilesProvider(widget.project.id));
        if (mounted) {
          AppToast.success(context, 'File deleted');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Delete failed: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(projectFilesProvider(widget.project.id));
    final selectedCategory = ref.watch(projectFilesCategoryProvider(widget.project.id));
    final currentUser = ref.watch(authControllerProvider).value;
    final canUpload = widget.project.acceptsWork;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar & Upload Action
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(projectFilesSearchProvider(widget.project.id).notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (val) {
                    ref.read(projectFilesSearchProvider(widget.project.id).notifier).state = val.trim();
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (canUpload)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showUploadDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryPill(
                  label: 'All Files',
                  isSelected: selectedCategory == 'all',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'all',
                ),
                const SizedBox(width: 8),
                _CategoryPill(
                  label: 'Specifications',
                  isSelected: selectedCategory == 'specification',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'specification',
                ),
                const SizedBox(width: 8),
                _CategoryPill(
                  label: 'Design Assets',
                  isSelected: selectedCategory == 'design',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'design',
                ),
                const SizedBox(width: 8),
                _CategoryPill(
                  label: 'Documents',
                  isSelected: selectedCategory == 'document',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'document',
                ),
                const SizedBox(width: 8),
                _CategoryPill(
                  label: 'Reports',
                  isSelected: selectedCategory == 'report',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'report',
                ),
                const SizedBox(width: 8),
                _CategoryPill(
                  label: 'Archives',
                  isSelected: selectedCategory == 'archive',
                  onTap: () => ref.read(projectFilesCategoryProvider(widget.project.id).notifier).state = 'archive',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Files Grid / List
          Expanded(
            child: filesAsync.when(
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No files uploaded yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Share documents, specifications, designs, or zip files with project members.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        if (canUpload) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload First File'),
                            onPressed: () => _showUploadDialog(context),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: files.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final canDelete = currentUser?.isSuperAdmin == true ||
                        currentUser?.id == widget.project.teamLeadId ||
                        currentUser?.id == file.uploaderId;

                    return _FileCard(
                      file: file,
                      canDelete: canDelete,
                      onDelete: () => _deleteFile(file),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Failed to load files: $err', style: TextStyle(color: AppColors.rose)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.canDelete,
    required this.onDelete,
  });

  final ProjectFileModel file;
  final bool canDelete;
  final VoidCallback onDelete;

  IconData _iconForFile() {
    if (file.isImage) return Icons.image;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.mimeType.contains('word') || file.fileName.endsWith('.docx')) return Icons.description;
    if (file.mimeType.contains('zip') || file.fileName.endsWith('.zip')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  Color _colorForFile() {
    if (file.isImage) return AppColors.primary;
    if (file.isPdf) return AppColors.rose;
    if (file.mimeType.contains('zip')) return AppColors.amber;
    return AppColors.emerald;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForFile();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconForFile(), color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          file.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file.category.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${file.formattedSize} • Uploaded by ${file.uploaderName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (file.description != null && file.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        file.description!,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              tooltip: 'Download / View',
              onPressed: () {
                AppToast.success(context, 'Downloading ${file.fileName}...');
              },
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.rose),
                tooltip: 'Delete File',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
