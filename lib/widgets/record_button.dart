import 'package:flutter/material.dart';

/// Circular record button with a pulsing animation while active.
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.enabled,
    required this.onPressed,
  });

  final bool isRecording;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer ring pulses when recording is active.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isRecording ? 10 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isRecording
                  ? colorScheme.error.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isRecording ? colorScheme.error : colorScheme.primary,
              minimumSize: const Size(160, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(isRecording ? Icons.fiber_manual_record : Icons.mic),
            label: Text(isRecording ? 'Recording…' : 'Record'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRecording ? 'Tap Stop when finished' : 'Tap to start recording',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
