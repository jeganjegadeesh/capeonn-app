class EmployeeDocumentItem {
  const EmployeeDocumentItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.documentType, // resume, id_proof, contract, certificate, educational, other
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.uploadedBy,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String documentType;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final Map<String, dynamic>? uploadedBy;
  final String createdAt;

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory EmployeeDocumentItem.fromJson(Map<String, dynamic> json) {
    return EmployeeDocumentItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      documentType: json['document_type'] as String? ?? 'other',
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String? ?? 'file',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String?,
      uploadedBy: json['uploaded_by'] is Map<String, dynamic> ? json['uploaded_by'] as Map<String, dynamic> : null,
      createdAt: json['created_at'] as String,
    );
  }
}

class EmployeeHistoryItem {
  const EmployeeHistoryItem({
    required this.id,
    required this.userId,
    required this.eventType, // joined, department_change, designation_change, role_change, reporting_change, promotion, note
    required this.title,
    this.description,
    this.metadata,
    required this.effectiveDate,
    this.performedBy,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String eventType;
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String effectiveDate;
  final Map<String, dynamic>? performedBy;
  final String createdAt;

  factory EmployeeHistoryItem.fromJson(Map<String, dynamic> json) {
    return EmployeeHistoryItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      eventType: json['event_type'] as String? ?? 'note',
      title: json['title'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
      effectiveDate: json['effective_date'] as String,
      performedBy: json['performed_by'] is Map<String, dynamic> ? json['performed_by'] as Map<String, dynamic> : null,
      createdAt: json['created_at'] as String,
    );
  }
}
