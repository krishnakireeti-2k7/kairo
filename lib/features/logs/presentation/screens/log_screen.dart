import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';
import 'package:kairo/features/logs/presentation/widgets/severity_slider.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(logFormProvider);
    final isSubmitting = ref.watch(logSubmissionProvider);
    final formNotifier = ref.read(logFormProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -30,
              child: _AmbientGlow(
                size: 220,
                color: const Color(0xFF79D9E2).withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -40,
              child: _AmbientGlow(
                size: 240,
                color: const Color(0xFF8FB9F7).withValues(alpha: 0.12),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TopBar(),
                        const SizedBox(height: 28),
                        const Text(
                          'Log\nSymptom',
                          style: TextStyle(
                            fontSize: 58,
                            height: 0.88,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC8DCFB),
                            letterSpacing: -2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Help us understand how you feel right now.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color: Color(0xFFB7C0CB),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'What are you feeling?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF1F5F9),
                                ),
                              ),
                            ),
                            Text(
                              'STEP 1 OF 3',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 1.6,
                                color: Color(0xFFAED0FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SymptomInputField(
                          value: form.symptomSearch,
                          onChanged: formNotifier.setSymptomSearch,
                          onSubmitted: formNotifier.addSymptom,
                        ),
                        const SizedBox(height: 16),
                        if (form.symptoms.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF182129),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(
                                  0xFFDBE3ED,
                                ).withValues(alpha: 0.05),
                              ),
                            ),
                            child: const Text(
                              'Type a symptom and press enter to add it.',
                              style: TextStyle(
                                color: Color(0xFF8E99A7),
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: form.symptoms
                                .map(
                                  (symptom) => _SymptomChip(
                                    label: symptom,
                                    onRemove: () =>
                                        formNotifier.removeSymptom(symptom),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 28),
                        SeveritySlider(
                          value: form.severity,
                          onChanged: (value) => ref
                              .read(logFormProvider.notifier)
                              .setSeverity(value.round()),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _durationPresets
                              .map(
                                (preset) => _DurationPill(
                                  label: preset.label,
                                  selected: form.duration == preset.minutes,
                                  onTap: () => ref
                                      .read(logFormProvider.notifier)
                                      .setDuration(preset.minutes),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _DurationInputField(
                          duration: form.duration,
                          onChanged: ref
                              .read(logFormProvider.notifier)
                              .setDuration,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Timestamp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TimestampCard(
                          timestamp: form.timestamp,
                          onEdit: () async {
                            final updatedTimestamp = await _pickTimestamp(
                              context,
                              form.timestamp,
                            );
                            if (updatedTimestamp != null) {
                              ref
                                  .read(logFormProvider.notifier)
                                  .setTimestamp(updatedTimestamp);
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Additional Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _NotesField(
                          initialValue: form.notes,
                          onChanged: ref
                              .read(logFormProvider.notifier)
                              .setNotes,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1D5C96), Color(0xFF9DC4FF)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF74AAFF,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final repository = ref.read(
                                        logRepositoryProvider,
                                      );
                                      final submissionNotifier = ref.read(
                                        logSubmissionProvider.notifier,
                                      );
                                      try {
                                        submissionNotifier.setSubmitting(true);
                                        if (form.symptomSearch
                                            .trim()
                                            .isNotEmpty) {
                                          formNotifier.addSymptom(
                                            form.symptomSearch,
                                          );
                                        }
                                        final latestForm = ref.read(
                                          logFormProvider,
                                        );
                                        await repository.createLog(
                                          severity: latestForm.severity,
                                          duration: latestForm.duration,
                                          notes: latestForm.notes,
                                          timestamp: latestForm.timestamp,
                                          symptoms: latestForm.symptoms,
                                        );
                                        ref.invalidate(logsProvider);
                                        formNotifier.reset();
                                        if (!context.mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Symptom log saved successfully.',
                                              ),
                                            ),
                                          );
                                        context.pop();
                                      } catch (error) {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(error.toString()),
                                              backgroundColor: const Color(
                                                0xFF93000A,
                                              ),
                                            ),
                                          );
                                      } finally {
                                        submissionNotifier.setSubmitting(false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0B243C),
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Log Entry',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0B243C),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<DateTime?> _pickTimestamp(
    BuildContext context,
    DateTime initialValue,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFAED0FF),
              surface: Color(0xFF182129),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF111A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) {
      return null;
    }

    if (!context.mounted) {
      return null;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFAED0FF),
              surface: Color(0xFF182129),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) {
      return DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        initialValue.hour,
        initialValue.minute,
      );
    }

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF4D1E32),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🧑🏻‍⚕️', style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Kairo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5F7FA),
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF141E26),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFFD8E6FF),
          ),
        ),
      ],
    );
  }
}

class _SymptomInputField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _SymptomInputField({
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_SymptomInputField> createState() => _SymptomInputFieldState();
}

class _SymptomInputFieldState extends State<_SymptomInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SymptomInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: (value) {
        widget.onSubmitted(value);
        _controller.clear();
      },
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Color(0xFFF5F7FA), fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Type a symptom and press enter',
        hintStyle: const TextStyle(color: Color(0xFF8E99A7), fontSize: 16),
        prefixIcon: const Icon(
          Icons.add_circle_outline,
          color: Color(0xFF8E99A7),
        ),
        filled: true,
        fillColor: const Color(0xFF313A43),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF7CDADF)),
        ),
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SymptomChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF134D87),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E78C6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.isEmpty ? label : label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAED0FF),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFFAED0FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF184F85) : const Color(0xFF28323D),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFFAED0FF)
                  : const Color(0xFFF5F7FA),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationInputField extends ConsumerStatefulWidget {
  final int duration;
  final ValueChanged<int> onChanged;

  const _DurationInputField({required this.duration, required this.onChanged});

  @override
  ConsumerState<_DurationInputField> createState() =>
      _DurationInputFieldState();
}

class _DurationInputFieldState extends ConsumerState<_DurationInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.duration.toString());
  }

  @override
  void didUpdateWidget(covariant _DurationInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration &&
        _controller.text != widget.duration.toString()) {
      _controller.text = widget.duration.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Color(0xFFF5F7FA), fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Duration in minutes',
        labelStyle: const TextStyle(color: Color(0xFF9CA7B6)),
        suffixText: 'mins',
        suffixStyle: const TextStyle(color: Color(0xFF9CA7B6)),
        filled: true,
        fillColor: const Color(0xFF182129),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF7CDADF)),
        ),
      ),
      onChanged: (value) {
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}

class _TimestampCard extends StatelessWidget {
  final DateTime timestamp;
  final Future<void> Function() onEdit;

  const _TimestampCard({required this.timestamp, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182129),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF103B59),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded, color: Color(0xFFAED0FF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB7C0CB),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFFAED0FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends ConsumerStatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _NotesField({required this.initialValue, required this.onChanged});

  @override
  ConsumerState<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends ConsumerState<_NotesField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 5,
      onChanged: widget.onChanged,
      style: const TextStyle(
        color: Color(0xFFF5F7FA),
        fontSize: 16,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText:
            'Any other observations? (e.g. pain quality, environmental factors)',
        hintStyle: const TextStyle(
          color: Color(0xFF8E99A7),
          fontSize: 16,
          height: 1.4,
        ),
        filled: true,
        fillColor: const Color(0xFF313A43),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF7CDADF)),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minutes = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minutes $suffix';
}

class _DurationPreset {
  final String label;
  final int minutes;

  const _DurationPreset({required this.label, required this.minutes});
}

const _durationPresets = [
  _DurationPreset(label: '< 30m', minutes: 30),
  _DurationPreset(label: '1h', minutes: 60),
  _DurationPreset(label: '4h', minutes: 240),
  _DurationPreset(label: 'All Day', minutes: 720),
];
