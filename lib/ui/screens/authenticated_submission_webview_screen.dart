import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/language.dart';
import '../../data/models/saved_problem.dart';
import '../../data/models/submission_attempt.dart';
import '../widgets/difficulty_badge.dart';

class SubmissionResult {
  final SubmissionVerdict verdict;
  final String? submissionId;
  final String? details;

  const SubmissionResult({
    required this.verdict,
    this.submissionId,
    this.details,
  });
}

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
  bool _isLoggedIn = false;
  bool _isSubmitting = false;
  String _submissionProgressText = '';
  bool _isDesktopMode = false;

  static const String _desktopUserAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
  static const String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.127 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.problem.url.isNotEmpty
        ? widget.problem.url
        : SavedProblem.generateUrl(widget.problem.slug);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setUserAgent(_mobileUserAgent)
      ..addJavaScriptChannel(
        'LeetStreakBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _handleBridgeMessage(msg.message);
        },
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
            _checkAuthStatus();
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

  Future<void> _checkAuthStatus() async {
    try {
      final jsCheck = '''
        (function() {
          function getCookie(name) {
            let matches = document.cookie.match(new RegExp("(?:^|; )" + name.replace(/([\\.\$?*|{}\\(\\)\\[\\]\\\\\\/\\+^])/g, '\\\\\$1') + "=([^;]*)"));
            return matches ? decodeURIComponent(matches[1]) : null;
          }
          const session = getCookie('LEETCODE_SESSION');
          return JSON.stringify({
            hasSession: !!session,
            cookiesCount: document.cookie.length
          });
        })()
      ''';

      final res = await _controller.runJavaScriptReturningResult(jsCheck);
      final dataStr = res.toString();
      // Handle string or json response
      final cleanStr = dataStr.startsWith('"') && dataStr.endsWith('"')
          ? jsonDecode(dataStr) as String
          : dataStr;
      final parsed = jsonDecode(cleanStr) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _isLoggedIn = parsed['hasSession'] == true;
        });
      }
    } catch (_) {}
  }

  void _toggleDesktopMode() {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });
    _controller.setUserAgent(_isDesktopMode ? _desktopUserAgent : _mobileUserAgent);
    _controller.reload();
  }

  void _navigateToLogin() {
    _controller.loadRequest(Uri.parse(AppConstants.leetCodeLoginUrl));
  }

  void _navigateToProblem() {
    _controller.loadRequest(Uri.parse(widget.problem.url));
  }

  void _handleBridgeMessage(String rawMessage) {
    try {
      final data = jsonDecode(rawMessage) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'progress') {
        setState(() {
          _submissionProgressText = data['step'] as String? ?? 'Processing...';
        });
      } else if (type == 'error') {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorDialog(
          title: 'Submission Failed',
          message: data['message'] as String? ?? 'Unknown error occurred.',
        );
      } else if (type == 'verdict') {
        setState(() {
          _isSubmitting = false;
        });

        final statusMsg = data['statusMsg'] as String? ?? 'Unknown';
        final submissionId = data['submissionId'] as String?;
        final runtime = data['runtime'] as String? ?? '';
        final memory = data['memory'] as String? ?? '';
        final verdict = SubmissionVerdict.fromString(statusMsg);
        final details = 'Runtime: $runtime, Memory: $memory';

        if (verdict == SubmissionVerdict.accepted) {
          _showVerdictDialog(
            isAccepted: true,
            title: '✓ Solution Accepted!',
            subtitle: 'Runtime: $runtime • Memory: $memory',
            onDismiss: () {
              Navigator.pop(
                context,
                SubmissionResult(
                  verdict: SubmissionVerdict.accepted,
                  submissionId: submissionId,
                  details: details,
                ),
              );
            },
          );
        } else {
          final correct = data['totalCorrect'] ?? 0;
          final total = data['totalTestcases'] ?? 0;
          _showVerdictDialog(
            isAccepted: false,
            title: 'Verdict: $statusMsg',
            subtitle: total > 0 ? '$correct / $total test cases passed' : 'Check submission on LeetCode for details.',
            onDismiss: () {
              Navigator.pop(
                context,
                SubmissionResult(
                  verdict: verdict,
                  submissionId: submissionId,
                  details: details,
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog(title: 'Error', message: 'Failed to parse response: $e');
    }
  }

  Future<void> _startOneTapSubmission() async {
    setState(() {
      _isSubmitting = true;
      _submissionProgressText = 'Connecting to LeetCode session...';
    });

    final lang = SupportedLanguage.fromName(widget.problem.language);
    final langCode = lang.code; // e.g. "python3", "cpp", "java"
    final slug = widget.problem.slug;
    final codeJson = jsonEncode(widget.problem.sourceCode);
    final qId = widget.problem.leetCodeId?.toString() ?? '0';

    final script = '''
      (async function() {
        function send(obj) {
          try {
            window.LeetStreakBridge.postMessage(JSON.stringify(obj));
          } catch(e) {
            console.error(e);
          }
        }

        function getCookie(name) {
          let matches = document.cookie.match(new RegExp("(?:^|; )" + name.replace(/([\\.\$?*|{}\\(\\)\\[\\]\\\\\\/\\+^])/g, '\\\\\$1') + "=([^;]*)"));
          return matches ? decodeURIComponent(matches[1]) : null;
        }

        const session = getCookie('LEETCODE_SESSION');
        if (!session) {
          send({
            type: 'error',
            code: 'NOT_LOGGED_IN',
            message: 'You are not logged in to LeetCode. Please log in first using the Sign In button above.'
          });
          return;
        }

        let csrfToken = getCookie('csrftoken') || '';
        send({ type: 'progress', step: 'Verifying problem metadata...' });

        let qId = "$qId";
        if (!qId || qId === "0" || qId === "null") {
          try {
            const qRes = await fetch('/graphql', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'x-csrftoken': csrfToken
              },
              body: JSON.stringify({
                query: 'query getQuestionDetail(\$titleSlug: String!) { question(titleSlug: \$titleSlug) { questionId questionFrontendId } }',
                variables: { titleSlug: "$slug" }
              })
            });
            const qData = await qRes.json();
            if (qData.data && qData.data.question) {
              qId = qData.data.question.questionId || qData.data.question.questionFrontendId;
            }
          } catch (e) {
            console.error('Failed to get question ID via GraphQL:', e);
          }
        }

        send({ type: 'progress', step: 'Submitting solution to LeetCode ($langCode)...' });

        try {
          const submitRes = await fetch('/problems/$slug/submit/', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-csrftoken': csrfToken
            },
            body: JSON.stringify({
              lang: "$langCode",
              question_id: qId,
              typed_code: $codeJson
            })
          });

          if (!submitRes.ok) {
            const errText = await submitRes.text();
            let msg = 'HTTP ' + submitRes.status + ' error';
            if (submitRes.status === 403) msg = 'Session expired or CSRF token rejected. Please reload page or re-login.';
            if (submitRes.status === 429) msg = 'Rate limit exceeded. Please wait a minute before submitting again.';
            send({ type: 'error', code: 'HTTP_' + submitRes.status, message: msg });
            return;
          }

          const submitData = await submitRes.json();
          const submissionId = submitData.submission_id;
          if (!submissionId) {
            send({ type: 'error', code: 'NO_SUBMISSION_ID', message: 'No submission ID returned: ' + JSON.stringify(submitData) });
            return;
          }

          send({ type: 'progress', step: 'Judging submission #' + submissionId + '...' });

          // Poll for verdict (up to 40 seconds)
          for (let i = 0; i < 35; i++) {
            await new Promise(r => setTimeout(r, 1200));
            try {
              const checkRes = await fetch('/submissions/detail/' + submissionId + '/check/');
              if (checkRes.ok) {
                const checkData = await checkRes.json();
                if (checkData.state === 'SUCCESS') {
                  send({
                    type: 'verdict',
                    submissionId: submissionId.toString(),
                    statusMsg: checkData.status_msg,
                    runtime: checkData.status_runtime || '',
                    memory: checkData.status_memory || '',
                    statusCode: checkData.status_code,
                    totalCorrect: checkData.total_correct,
                    totalTestcases: checkData.total_testcases
                  });
                  return;
                } else {
                  send({ type: 'progress', step: 'Judging test cases (' + (checkData.state || 'RUNNING') + ')...' });
                }
              }
            } catch (err) {
              console.error(err);
            }
          }

          send({
            type: 'error',
            code: 'TIMEOUT',
            message: 'Submission #' + submissionId + ' was submitted, but verdict polling timed out. Please check your submission history.'
          });

        } catch (err) {
          send({ type: 'error', code: 'FETCH_ERROR', message: 'Network error submitting to LeetCode: ' + err.toString() });
        }
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog(title: 'Error', message: 'Failed to run submission script: $e');
    }
  }

  void _showVerdictDialog({
    required bool isAccepted,
    required String title,
    required String subtitle,
    required VoidCallback onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isAccepted ? AppColors.accepted : AppColors.wrongAnswer,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isAccepted ? AppColors.accepted : AppColors.wrongAnswer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAccepted ? AppColors.primary : AppColors.surfaceLight,
                foregroundColor: isAccepted ? Colors.black : AppColors.textPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(isAccepted ? 'Confirm & Save Streak' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.wrongAnswer),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          if (!_isLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToLogin();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Log In Now'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCodeToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.problem.sourceCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Source code copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showManualConfirmSheet() {
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
                  Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Manual Verification',
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
                'If you manually pasted and submitted code in the LeetCode web page, choose the result you obtained:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(
                          context,
                          const SubmissionResult(verdict: SubmissionVerdict.wrongAnswer),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.wrongAnswer,
                        side: const BorderSide(color: AppColors.wrongAnswer),
                      ),
                      child: const Text('Failed / Other'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(
                          context,
                          const SubmissionResult(
                            verdict: SubmissionVerdict.accepted,
                            details: 'Manually verified by user',
                          ),
                        );
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
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(width: 6),
                Text(
                  _isLoggedIn ? '✓ Logged In' : 'Not Logged In',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isLoggedIn ? AppColors.accepted : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDesktopMode ? Icons.smartphone_rounded : Icons.desktop_mac_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: _isDesktopMode ? 'Switch to Mobile View' : 'Switch to Desktop View',
            onPressed: _toggleDesktopMode,
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
            tooltip: 'Copy Code',
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
          Column(
            children: [
              // Authentication Banner
              if (!_isLoggedIn && !isLoginPage)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: AppColors.primaryContainer,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'You are not logged in. Sign in once to enable 1-tap streak submissions.',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else if (isLoginPage)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: AppColors.surfaceElevated,
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sign in to LeetCode. Your cookies stay exclusively on this phone.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToProblem,
                        child: const Text('Back to Problem', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // The WebView
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),

          // Loading bar
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

          // Submitting overlay modal
          if (_isSubmitting)
            Container(
              color: Colors.black.withAlpha(200),
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Submitting Solution',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _submissionProgressText,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showManualConfirmSheet,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Manual'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : (_isLoggedIn ? _startOneTapSubmission : _navigateToLogin),
                  icon: Icon(
                    _isLoggedIn ? Icons.bolt_rounded : Icons.login_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isLoggedIn ? '1-Tap Submit & Verify' : 'Sign In to LeetCode',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoggedIn ? AppColors.primary : AppColors.surfaceElevated,
                    foregroundColor: _isLoggedIn ? Colors.black : AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    elevation: _isLoggedIn ? 2 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
