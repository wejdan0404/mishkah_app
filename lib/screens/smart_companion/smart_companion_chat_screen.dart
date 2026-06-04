import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/ai/ai_service.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../../core/permissions/permission_flow.dart';
import '../../models/ai_message.dart';
import '../../models/ai_thread.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'activity_suggestion_registry.dart';
import 'services/transcribe_audio_service.dart';
import 'widgets/activity_suggestion_card.dart';
import 'widgets/bot_message_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/quick_reply_chip.dart';
import 'widgets/voice_reactive_mic_animation.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/user_message_bubble.dart';

class SmartCompanionChatScreen extends StatefulWidget {
  const SmartCompanionChatScreen({super.key});

  static const String routeName = '/smart-companion/chat';

  @override
  State<SmartCompanionChatScreen> createState() =>
      _SmartCompanionChatScreenState();
}

class _SmartCompanionChatScreenState extends State<SmartCompanionChatScreen> {
  final AiService _ai = AiService.instance;
  final TranscribeAudioService _transcriber = TranscribeAudioService();
  final AudioRecorder _recorder = AudioRecorder();

  AiThread? _thread;
  StreamSubscription<AiStreamEvent>? _activeStream;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatItem> _items = [
    _ChatItem.bot(
      'أنا هنا أسمعك وأساعدك ترتّب أفكارك بهدوء. ما الذي يشغلك اليوم؟',
    ),
  ];

  bool _isThinking = false;
  bool _conversationStarted = false;
  String? _activeRecordingPath;
  ChatInputMode _inputMode = ChatInputMode.idle;

  // Live microphone level (0..1) driving the voice animation. Fed from the
  // existing recorder's amplitude stream — no extra capture logic.
  StreamSubscription<Amplitude>? _amplitudeSub;
  double _amplitude = 0;

  // Maps the recorder's dBFS reading onto 0..1. Quiet speech sits well above
  // the floor; the clamp keeps silence at 0 and loud peaks at 1.
  static const double _minDbfs = -45;

  static const List<String> _quickReplies = [
    'أحس بتوتر',
    'عندي تشتت',
    'أفكاري كثيرة ايش اسوي',
    'احتاج هدوء',
  ];

  @override
  void dispose() {
    _activeStream?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String message) async {
    if (message.isEmpty || _isThinking) return;
    // The assistant runs server-side (auth required) — gated for guests.
    if (AuthService.isGuest) {
      showLoginRequiredToast(context);
      return;
    }
    setState(() {
      _items.add(_ChatItem.user(message));
      _isThinking = true;
      _conversationStarted = true;
      _textController.clear();
    });
    _scrollToBottom();

    try {
      _thread ??= await _ai.createThread();

      final stream = _ai.sendMessage(threadId: _thread!.id, content: message);
      // The typing indicator stays up for the whole reply; we buffer the text
      // and reveal it as one finished bubble — no empty placeholder bubble in
      // the meantime.
      final buffer = StringBuffer();
      String? suggestedSlug;
      bool errored = false;

      await for (final event in stream) {
        if (!mounted) return;
        if (event is AiStreamDelta) {
          buffer.write(event.text);
        } else if (event is AiStreamError) {
          _showSnack(event.message);
          errored = true;
          break;
        } else if (event is AiStreamComplete) {
          suggestedSlug = event.suggestedActivitySlug;
          break;
        }
      }

      if (!mounted) return;
      final String reply = buffer.toString().trim();
      if (reply.isNotEmpty) {
        setState(() {
          _isThinking = false;
          _items.add(
            _ChatItem.bot(reply, suggestedActivitySlug: suggestedSlug),
          );
        });
        _scrollToBottom();
      } else if (!errored) {
        _showSnack('ما وصلني ردك، جرّب مرة ثانية.');
      }
    } on ApiException catch (e) {
      _showSnack(_arabicForApiError(e));
    } catch (_) {
      _showSnack('صار خطأ غير متوقع، جرّب مرة ثانية.');
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  String _arabicForApiError(ApiException e) {
    if (e.code == 'AI_USAGE_EXCEEDED') return 'وصلت لحد رسائل اليوم. جرّب بكرة.';
    if (e.isConsentRequired) {
      return 'كمّل الموافقات في الإعدادات عشان تفعّل المرافق.';
    }
    if (e.isUnauthenticated) return 'انتهت الجلسة، سجّل دخولك من جديد.';
    if (e.isRateLimited) return 'محاولات كثيرة، خذ نفس وجرّب بعد شوي.';
    return e.message;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message, type: AppToastType.error);
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.microphone.status,
      request: () => Permission.microphone.request(),
      openSettings: openAppSettings,
      // No app dialogs for the mic: go straight to the OS prompt on first ask,
      // and straight to Settings if already denied (iOS won't re-prompt).
    );
    if (!mounted || !granted) return;

    try {
      final Directory dir = Directory.systemTemp;
      final String path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          // 44.1kHz: a standard hardware rate. Forcing a low 16kHz preferred
          // rate produced silent capture on iOS 26 (mic read a constant floor).
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      _listenToAmplitude();
      setState(() {
        _activeRecordingPath = path;
        _inputMode = ChatInputMode.listening;
      });
    } catch (_) {
      _showSnack('ما قدرت أبدأ التسجيل، تكفى جرب مرة ثانية.');
      if (mounted) setState(() => _inputMode = ChatInputMode.idle);
    }
  }

  void _listenToAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((Amplitude amp) {
      if (!mounted) return;
      final double level =
          ((amp.current - _minDbfs) / (0 - _minDbfs)).clamp(0.0, 1.0);
      setState(() => _amplitude = level);
    });
  }

  void _stopAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _amplitude = 0;
  }

  Future<void> _stopListening() async {
    if (_inputMode != ChatInputMode.listening) return;
    _stopAmplitude();
    setState(() => _inputMode = ChatInputMode.loading);
    try {
      final String? path = await _recorder.stop();
      if (path == null) throw Exception('no recording');
      final String transcript = await _transcriber.transcribe(File(path));
      if (!mounted) return;
      _textController
        ..text = transcript
        ..selection = TextSelection.collapsed(offset: transcript.length);
      setState(() => _inputMode = ChatInputMode.idle);
    } on TranscribeException catch (e) {
      _showSnack(e.message);
      if (mounted) setState(() => _inputMode = ChatInputMode.idle);
    } on SocketException {
      _showSnack('تأكّدي من اتصالك بالإنترنت وجرّبي مرة ثانية.');
      if (mounted) setState(() => _inputMode = ChatInputMode.idle);
    } catch (_) {
      _showSnack('ما قدرت أحوّل التسجيل، جرّب مرة ثانية.');
      if (mounted) setState(() => _inputMode = ChatInputMode.idle);
    } finally {
      _activeRecordingPath = null;
    }
  }

  Future<void> _cancelListening() async {
    _stopAmplitude();
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (_activeRecordingPath != null) {
      try {
        await File(_activeRecordingPath!).delete();
      } catch (_) {}
      _activeRecordingPath = null;
    }
    if (mounted) setState(() => _inputMode = ChatInputMode.idle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      resizeToAvoidBottomInset: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              const AppTopNav(title: 'اسأل مِشْكَاة'),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  itemCount: _items.length + (_isThinking ? 1 : 0),
                  separatorBuilder: (_, index) =>
                      SizedBox(height: _gapAt(index)),
                  itemBuilder: (context, index) {
                    if (_isThinking && index == _items.length) {
                      return const _TypingRow();
                    }
                    final item = _items[index];
                    return _buildItem(item);
                  },
                ),
              ),
              if (_inputMode == ChatInputMode.listening)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: VoiceReactiveMicAnimation(
                    amplitude: _amplitude,
                    isListening: true,
                    onTap: _stopListening,
                  ),
                ),
              if (!_conversationStarted &&
                  !_isThinking &&
                  _inputMode == ChatInputMode.idle)
                _quickRepliesRow(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: ChatInputBar(
                  controller: _textController,
                  mode: _inputMode,
                  onStartListening: _startListening,
                  onCancelListening: _cancelListening,
                  onSubmitted: _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _gapAt(int index) {
    final String current = _senderAt(index);
    final String next = _senderAt(index + 1);
    return current == next ? AppSpacing.md : AppSpacing.xl;
  }

  String _senderAt(int index) {
    if (index < _items.length) {
      switch (_items[index].type) {
        case _ChatItemType.user:
          return 'user';
        case _ChatItemType.bot:
          return 'bot';
      }
    }
    return 'bot';
  }

  Widget _quickRepliesRow() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.none,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final reply in _quickReplies)
              QuickReplyChip(
                label: reply,
                onTap: () => _send(reply),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_ChatItem item) {
    switch (item.type) {
      case _ChatItemType.bot:
        return _buildBotItem(item);
      case _ChatItemType.user:
        return UserMessageBubble(text: item.text);
    }
  }

  // Bot bubble, plus the activity suggestion card directly under it when the
  // backend grounded an activity that maps to a known exercise screen. The
  // card aligns with the bubble (the trailing gutter matches the avatar slot)
  // — no change to the bubble or list layout.
  Widget _buildBotItem(_ChatItem item) {
    final String? slug = item.suggestedActivitySlug;
    final ActivitySuggestion? suggestion =
        slug == null ? null : resolveActivitySuggestion(slug);
    if (suggestion == null) {
      return BotMessageBubble(text: item.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotMessageBubble(text: item.text),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ActivitySuggestionCard(
                colors: suggestion.colors,
                label: suggestion.label,
                description: suggestion.description,
                onTap: () => suggestion.open(context),
                ctaLabel: 'ابدأ النشاط',
              ),
            ),
            const SizedBox(width: AppSpacing.md + _BotMessageGutter.avatarSize),
          ],
        ),
      ],
    );
  }
}

/// Width of the avatar slot in [BotMessageBubble]'s trailing gutter, used to
/// keep the suggestion card's right edge aligned with the bubble's.
class _BotMessageGutter {
  const _BotMessageGutter._();
  static const double avatarSize = 44.936;
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Spacer(),
        TypingIndicator(),
        SizedBox(width: AppSpacing.md),
        SizedBox(width: 44.936),
      ],
    );
  }
}

enum _ChatItemType { bot, user }

class _ChatItem {
  _ChatItem._(this.type, this.text, {this.suggestedActivitySlug});

  factory _ChatItem.bot(String text, {String? suggestedActivitySlug}) =>
      _ChatItem._(
        _ChatItemType.bot,
        text,
        suggestedActivitySlug: suggestedActivitySlug,
      );
  factory _ChatItem.user(String text) => _ChatItem._(_ChatItemType.user, text);

  final _ChatItemType type;
  final String text;

  /// Set on assistant items when the backend grounded an activity suggestion
  /// for this reply (from the SSE `message.complete` event). Drives the
  /// tappable activity card rendered under the bubble.
  final String? suggestedActivitySlug;
}
