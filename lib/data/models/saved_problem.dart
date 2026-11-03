import 'difficulty.dart';

class SavedProblem {
  final int? id;
  final int? leetCodeId;
  final String title;
  final String slug;
  final String url;
  final Difficulty difficulty;
  final String language;
  final String sourceCode;
  final bool isAccepted;
  final DateTime dateAdded;
  final DateTime? lastSubmittedDate;
  final int submissionAttempts;
  final String? notes;

  const SavedProblem({
    this.id,
    this.leetCodeId,
    required this.title,
    required this.slug,
    required this.url,
    required this.difficulty,
    required this.language,
    required this.sourceCode,
    this.isAccepted = true,
    required this.dateAdded,
    this.lastSubmittedDate,
    this.submissionAttempts = 0,
    this.notes,
  });

  SavedProblem copyWith({
    int? id,
    int? leetCodeId,
    String? title,
    String? slug,
    String? url,
    Difficulty? difficulty,
    String? language,
    String? sourceCode,
    bool? isAccepted,
    DateTime? dateAdded,
    DateTime? lastSubmittedDate,
    int? submissionAttempts,
    String? notes,
  }) {
    return SavedProblem(
      id: id ?? this.id,
      leetCodeId: leetCodeId ?? this.leetCodeId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      url: url ?? this.url,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      sourceCode: sourceCode ?? this.sourceCode,
      isAccepted: isAccepted ?? this.isAccepted,
      dateAdded: dateAdded ?? this.dateAdded,
      lastSubmittedDate: lastSubmittedDate ?? this.lastSubmittedDate,
      submissionAttempts: submissionAttempts ?? this.submissionAttempts,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'leetcode_id': leetCodeId,
      'title': title,
      'slug': slug,
      'url': url,
      'difficulty': difficulty.name,
      'language': language,
      'source_code': sourceCode,
      'is_accepted': isAccepted ? 1 : 0,
      'date_added': dateAdded.toIso8601String(),
      'last_submitted_date': lastSubmittedDate?.toIso8601String(),
      'submission_attempts': submissionAttempts,
      'notes': notes,
    };
  }

  factory SavedProblem.fromMap(Map<String, dynamic> map) {
    return SavedProblem(
      id: map['id'] as int?,
      leetCodeId: map['leetcode_id'] as int?,
      title: map['title'] as String,
      slug: map['slug'] as String,
      url: map['url'] as String,
      difficulty: Difficulty.fromString(map['difficulty'] as String),
      language: map['language'] as String,
      sourceCode: map['source_code'] as String,
      isAccepted: (map['is_accepted'] as int?) == 1,
      dateAdded: DateTime.parse(map['date_added'] as String),
      lastSubmittedDate: map['last_submitted_date'] != null
          ? DateTime.parse(map['last_submitted_date'] as String)
          : null,
      submissionAttempts: (map['submission_attempts'] as int?) ?? 0,
      notes: map['notes'] as String?,
    );
  }

  /// Helper to generate LeetCode URL from slug if needed
  static String generateUrl(String slug) {
    final cleanSlug = slug.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-');
    return 'https://leetcode.com/problems/$cleanSlug/';
  }

  /// Helper to sanitize slug from title or input
  static String slugFromTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^[0-9]+\.\s*'), '') // remove leading problem numbers like "1. Two Sum"
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }
}

