import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kumbmela_multilingual/services/speech_service.dart';
import 'package:kumbmela_multilingual/widgets/record_button.dart';

/// Main screen — orchestrates recording, playback, upload, and display.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, SpeechService? speechService})
      : _speechService = speechService;

  final SpeechService? _speechService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SpeechService _speechService =
      widget._speechService ?? SpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // UI state
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isPlaying = false;
  String? _audioPath;
  String _transcript = '';
  String? _errorMessage;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _requestPermissionOnLaunch();
  }

  /// App flow step 1: ask for microphone permission when the app opens.
  Future<void> _requestPermissionOnLaunch() async {
    final granted = await _speechService.requestMicrophonePermission();
    if (!granted && mounted) {
      setState(() {
        _errorMessage =
            'Microphone permission denied. Grant access to record audio.';
      });
    }
  }

  /// Wire up audio player stream listeners for the replay widget.
  void _initAudioPlayer() {
    _positionSub = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _playbackPosition = position);
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _playbackDuration = duration);
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Recording flow
  // ---------------------------------------------------------------------------

  Future<void> _onRecordPressed() async {
    setState(() => _errorMessage = null);

    try {
      final path = await _speechService.startRecording();
      setState(() {
        _isRecording = true;
        _audioPath = path;
        _transcript = '';
      });
    } on SpeechServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _onStopPressed() async {
    setState(() {
      _errorMessage = null;
      _isRecording = false;
    });

    try {
      final path = await _speechService.stopRecording();
      setState(() => _audioPath = path);

      // Automatically upload after stopping — core app flow.
      await _transcribeRecording(path);
    } on SpeechServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Transcription flow
  // ---------------------------------------------------------------------------

  Future<void> _transcribeRecording(String path) async {
    setState(() {
      _isTranscribing = true;
      _errorMessage = null;
    });

    try {
      final result = await _speechService.transcribeAudio(path);
      if (mounted) {
        setState(() => _transcript = result.text);
      }
    } on SpeechServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }

    await _audioPlayer.play(DeviceFileSource(_audioPath!));
    setState(() => _isPlaying = true);
  }

  Future<void> _seekTo(double value) async {
    await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ---------------------------------------------------------------------------
  // Clear / reset
  // ---------------------------------------------------------------------------

  Future<void> _onClearPressed() async {
    await _audioPlayer.stop();
    setState(() {
      _isRecording = false;
      _isTranscribing = false;
      _isPlaying = false;
      _audioPath = null;
      _transcript = '';
      _errorMessage = null;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _speechService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = _isRecording || _isTranscribing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // --- Audio section ---
                  _SectionCard(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    child: Column(
                      children: [
                        RecordButton(
                          isRecording: _isRecording,
                          enabled: !_isTranscribing,
                          onPressed: _onRecordPressed,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _isRecording ? _onStopPressed : null,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Stop'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        if (_audioPath != null) ...[
                          const SizedBox(height: 20),
                          _AudioPlayerBar(
                            isPlaying: _isPlaying,
                            position: _playbackPosition,
                            duration: _playbackDuration,
                            formatDuration: _formatDuration,
                            onPlayPause: _togglePlayback,
                            onSeek: _seekTo,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Transcript section ---
                  Expanded(
                    child: _SectionCard(
                      icon: Icons.text_fields,
                      label: 'Output',
                      expandChild: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _transcript.isEmpty
                                      ? 'Transcription will appear here…'
                                      : _transcript,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _transcript.isEmpty
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: isBusy ? null : _onClearPressed,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Full-screen loading overlay while the API call is in progress.
          if (_isTranscribing)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Transcribing audio…',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private UI helpers
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
    this.expandChild = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerBar extends StatelessWidget {
  const _AudioPlayerBar({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.formatDuration,
    required this.onPlayPause,
    required this.onSeek,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPlayPause,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          Text(
            formatDuration(position),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Slider(
              value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
              max: maxMs.toDouble(),
              onChanged: duration.inMilliseconds > 0 ? onSeek : null,
            ),
          ),
          Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}
