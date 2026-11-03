import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum SubmissionVerdict {
  accepted,
  wrongAnswer,
  runtimeError,
  timeLimitExceeded,
  pending,
  failed;

  String get displayName {
    switch (this) {
      case SubmissionVerdict.accepted:
        return 'Accepted';
      case SubmissionVerdict.wrongAnswer:
        return 'Wrong Answer';
      case SubmissionVerdict.runtimeError:
        return 'Runtime Error';
      case SubmissionVerdict.timeLimitExceeded:
        return 'Time Limit Exceeded';
      case SubmissionVerdict.pending:
        return 'Pending';
      case SubmissionVerdict.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case SubmissionVerdict.accepted:
        return AppColors.accepted;
      case SubmissionVerdict.wrongAnswer:
        return AppColors.wrongAnswer;
      case SubmissionVerdict.runtimeError:
        return AppColors.runtimeError;
      case SubmissionVerdict.timeLimitExceeded:
        return AppColors.runtimeError;
      case SubmissionVerdict.pending:
        return AppColors.pending;
      case SubmissionVerdict.failed:
        return AppColors.failed;
    }
  }

  static SubmissionVerdict fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '').replaceAll('_', '').trim()) {
      case 'accepted':
        return SubmissionVerdict.accepted;
      case 'wronganswer':
        return SubmissionVerdict.wrongAnswer;
      case 'runtimeerror':
        return SubmissionVerdict.runtimeError;
      case 'timelimitexceeded':
      case 'tle':
        return SubmissionVerdict.timeLimitExceeded;
      case 'pending':
        return SubmissionVerdict.pending;
      default:
        return SubmissionVerdict.failed;
    }
  }
}

class SubmissionAttempt {
  final int? id;
  final int problemId;
  final String problemTitle;
  final String problemSlug;
  final String language;
  final DateTime timestamp;
  final SubmissionVerdict verdict;
  final String? leetCodeSubmissionId;
  final String? details;

  const SubmissionAttempt({
    this.id,
    required this.problemId,
    required this.problemTitle,
    required this.problemSlug,
    required this.language,
    required this.timestamp,
    required this.verdict,
    this.leetCodeSubmissionId,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'problem_id': problemId,
      'problem_title': problemTitle,
      'problem_slug': problemSlug,
      'language': language,
      'timestamp': timestamp.toIso8601String(),
      'verdict': verdict.name,
      'leetcode_submission_id': leetCodeSubmissionId,
      'details': details,
    };
  }

  factory SubmissionAttempt.fromMap(Map<String, dynamic> map) {
    return SubmissionAttempt(
      id: map['id'] as int?,
      problemId: map['problem_id'] as int,
      problemTitle: map['problem_title'] as String,
      problemSlug: map['problem_slug'] as String,
      language: map['language'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      verdict: SubmissionVerdict.fromString(map['verdict'] as String),
      leetCodeSubmissionId: map['leetcode_submission_id'] as String?,
      details: map['details'] as String?,
    );
  }
}

