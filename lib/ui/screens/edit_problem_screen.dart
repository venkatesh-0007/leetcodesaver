import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/language.dart';
import '../../data/models/saved_problem.dart';
import '../../providers/problem_providers.dart';

class EditProblemScreen extends ConsumerStatefulWidget {
  final SavedProblem? problemToEdit;

  const EditProblemScreen({super.key, this.problemToEdit});

  @override
  ConsumerState<EditProblemScreen> createState() => _EditProblemScreenState();
}

class _EditProblemScreenState extends ConsumerState<EditProblemScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _idController;
  late final TextEditingController _slugController;
  late final TextEditingController _urlController;
  late final TextEditingController _codeController;
  late final TextEditingController _notesController;

  Difficulty _difficulty = Difficulty.easy;
  String _selectedLanguage = 'Python 3';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.problemToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _idController = TextEditingController(text: p?.leetCodeId?.toString() ?? '');
    _slugController = TextEditingController(text: p?.slug ?? '');
    _urlController = TextEditingController(text: p?.url ?? '');
    _codeController = TextEditingController(text: p?.sourceCode ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    if (p != null) {
      _difficulty = p.difficulty;
      _selectedLanguage = p.language;
    }

    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    if (widget.problemToEdit == null && _slugController.text.isEmpty) {
      final slug = SavedProblem.slugFromTitle(_titleController.text);
      _slugController.text = slug;
      _urlController.text = SavedProblem.generateUrl(slug);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _idController.dispose();
    _slugController.dispose();
    _urlController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['py', 'cpp', 'java', 'js', 'ts', 'go', 'rs', 'kt', 'c', 'cs', 'swift', 'txt'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final pickedFile = files.first;
        final file = File(pickedFile.path!);
        final content = await file.readAsString();
        final ext = pickedFile.extension ?? '';

        final detectedLang = SupportedLanguage.fromExtension(ext);

        setState(() {
          _codeController.text = content;
          _selectedLanguage = detectedLang.name;

          if (_titleController.text.isEmpty) {
            final fileNameWithoutExt = pickedFile.name.replaceAll(RegExp(r'\.[^.]+$'), '');
            _titleController.text = fileNameWithoutExt;
            final slug = SavedProblem.slugFromTitle(fileNameWithoutExt);
            _slugController.text = slug;
            _urlController.text = SavedProblem.generateUrl(slug);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Imported from ${pickedFile.name} (${detectedLang.name})'),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read file: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final slug = _slugController.text.trim().isNotEmpty
        ? _slugController.text.trim()
        : SavedProblem.slugFromTitle(title);
    final url = _urlController.text.trim().isNotEmpty
        ? _urlController.text.trim()
        : SavedProblem.generateUrl(slug);
    final id = int.tryParse(_idController.text.trim());
    final code = _codeController.text;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    final existing = widget.problemToEdit;
    final problem = SavedProblem(
      id: existing?.id,
      leetCodeId: id,
      title: title,
      slug: slug,
      url: url,
      difficulty: _difficulty,
      language: _selectedLanguage,
      sourceCode: code,
      isAccepted: existing?.isAccepted ?? true,
      dateAdded: existing?.dateAdded ?? DateTime.now(),
      lastSubmittedDate: existing?.lastSubmittedDate,
      submissionAttempts: existing?.submissionAttempts ?? 0,
      notes: notes,
    );

    if (existing == null) {
      await ref.read(problemListProvider.notifier).addProblem(problem);
    } else {
      await ref.read(problemListProvider.notifier).updateProblem(problem);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.problemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Solution' : 'Add Solution'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
            tooltip: 'Import from file (.py, .cpp, .java)',
            onPressed: _pickFile,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.check_rounded, color: AppColors.primary),
            tooltip: 'Save Solution',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Import Code Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Have a source file? Import from .py, .cpp, .java',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Browse', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Problem Title *',
                  hintText: 'e.g. Two Sum',
                  prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter a problem title' : null,
              ),

              const SizedBox(height: 14),

              // ID & Difficulty Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'LeetCode ID',
                        hintText: 'e.g. 1',
                        prefixIcon: Icon(Icons.numbers_rounded, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Difficulty>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        prefixIcon: Icon(Icons.speed_rounded, color: AppColors.textMuted),
                      ),
                      dropdownColor: AppColors.surfaceElevated,
                      items: Difficulty.values.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            d.displayName,
                            style: TextStyle(color: d.color, fontWeight: FontWeight.w700),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _difficulty = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Language Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Programming Language',
                  prefixIcon: Icon(Icons.terminal_rounded, color: AppColors.textMuted),
                ),
                dropdownColor: AppColors.surfaceElevated,
                items: SupportedLanguage.all.map((lang) {
                  return DropdownMenuItem(
                    value: lang.name,
                    child: Text(lang.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),

              const SizedBox(height: 14),

              // Slug & URL
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Problem Slug',
                  hintText: 'e.g. two-sum',
                  prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
                ),
                onChanged: (val) {
                  _urlController.text = SavedProblem.generateUrl(val);
                },
              ),

              const SizedBox(height: 14),

              // Source Code Editor
              const Text(
                'Source Code *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                maxLines: 12,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste or import accepted solution code here...',
                  fillColor: const Color(0xFF16181F),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter the solution code' : null,
              ),

              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Explanation (optional)',
                  hintText: 'Time & space complexity, approach summary...',
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
