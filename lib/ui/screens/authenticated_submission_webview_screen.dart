import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_problem.dart';
import '../../data/models/submission_attempt.dart';
import '../widgets/difficulty_badge.dart';

class AuthenticatedSubmissionWebviewScreen extends StatefulWidget {
  final SavedProblem problem;

  const AuthenticatedSubmissionWebviewScreen({
    super.key,
    required this.problem,
  });

  @override
  State<AuthenticatedSubmissionWebviewScreen> createState() =>
      _AuthenticatedSubmissionWebviewScreenState();
}

class _AuthenticatedSubmissionWebviewScreenState
    extends State<AuthenticatedSubmissionWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.problem.url.isNotEmpty
        ? widget.problem.url
        : SavedProblem.generateUrl(widget.problem.slug);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));

    // Automatically copy the solution code to clipboard for convenience
    Clipboard.setData(ClipboardData(text: widget.problem.sourceCode));
  }

  Future<void> _copyCodeToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.problem.sourceCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Source code copied to clipboard! Paste into LeetCode editor.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showConfirmVerdictDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.accepted, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Record Submission Result',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Did LeetCode confirm an "Accepted" verdict for this submission? Only genuine Accepted solutions will save your streak.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, SubmissionVerdict.wrongAnswer);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.wrongAnswer,
                        side: const BorderSide(color: AppColors.wrongAnswer),
                      ),
                      child: const Text('Not Accepted'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, SubmissionVerdict.accepted);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accepted,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Yes, Accepted!'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoginPage = _currentUrl.contains('/accounts/login') ||
        _currentUrl.contains('sign_in');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.problem.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                DifficultyBadge(difficulty: widget.problem.difficulty, fontSize: 10),
                const SizedBox(width: 6),
                Text(
                  widget.problem.language,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
            tooltip: 'Copy Solution Code',
            onPressed: _copyCodeToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Page',
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoginPage) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(100)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please log in to your LeetCode account. Credentials stay strictly in your local device browser.',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyCodeToClipboard,
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Copy Code'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showConfirmVerdictDialog,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Confirm Verdict'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
