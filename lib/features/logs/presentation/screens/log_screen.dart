import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/logs/presentation/providers/log_provider.dart';
import 'package:kairo/features/logs/presentation/widgets/severity_slider.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(logFormProvider);
    final logsState = ref.watch(logProvider);
    final isSubmitting = logsState.isLoading;

    final filteredSymptoms = _symptomOptions
        .where(
          (option) =>
              form.symptomSearch.trim().isEmpty ||
              option.label.toLowerCase().contains(
                form.symptomSearch.toLowerCase(),
              ),
        )
        .toList();

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
                        _SearchField(
                          value: form.symptomSearch,
                          onChanged: ref
                              .read(logFormProvider.notifier)
                              .setSymptomSearch,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: filteredSymptoms
                              .map(
                                (option) => _SelectionChip(
                                  label: option.label,
                                  selected: form.selectedSymptoms.contains(
                                    option.key,
                                  ),
                                  selectedTextColor: const Color(0xFFAED0FF),
                                  onTap: () => ref
                                      .read(logFormProvider.notifier)
                                      .toggleSymptom(option.key),
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
                          'Contextual Triggers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _contextOptions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.9,
                              ),
                          itemBuilder: (context, index) {
                            final option = _contextOptions[index];
                            final selected = form.selectedContexts.contains(
                              option.key,
                            );

                            return _ContextCard(
                              label: option.label,
                              icon: option.icon,
                              iconColor: option.iconColor,
                              selected: selected,
                              onTap: () => ref
                                  .read(logFormProvider.notifier)
                                  .toggleContext(option.key),
                            );
                          },
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
                                      try {
                                        await ref
                                            .read(logProvider.notifier)
                                            .createLog(
                                              severity: form.severity,
                                              duration: form.duration,
                                              notes: form.notes,
                                              timestamp: form.timestamp,
                                            );
                                        ref
                                            .read(logFormProvider.notifier)
                                            .reset();
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
                                        Navigator.of(context).pop();
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
                const _BottomNavBar(activeIndex: 1),
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

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFFF5F7FA), fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Search symptoms...',
        hintStyle: const TextStyle(color: Color(0xFF8E99A7), fontSize: 16),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E99A7)),
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

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedTextColor;

  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF134D87) : const Color(0xFF222C35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2E78C6)
                  : const Color(0xFFDBE3ED).withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? selectedTextColor : const Color(0xFFE3EAF3),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFFAED0FF),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _ContextCard({
    required this.label,
    required this.icon,
    required this.iconColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D3942) : const Color(0xFF182129),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1F8492)
                  : const Color(0xFFDBE3ED).withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFFABF1F4)
                        : const Color(0xFFF5F7FA),
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

class _BottomNavBar extends StatelessWidget {
  final int activeIndex;

  const _BottomNavBar({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'INSIGHTS'),
      (Icons.timeline_rounded, 'TIMELINE'),
      (Icons.description_outlined, 'REPORTS'),
      (Icons.person_rounded, 'PROFILE'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C151C).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDBE3ED).withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var index = 0; index < items.length; index++)
            _BottomNavItem(
              icon: items[index].$1,
              label: items[index].$2,
              active: index == activeIndex,
            ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF172C63) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFFDCE9FF) : const Color(0xFF8894A3),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.7,
              color: active ? const Color(0xFFDCE9FF) : const Color(0xFF8894A3),
            ),
          ),
        ],
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

class _UiOption {
  final String key;
  final String label;

  const _UiOption({required this.key, required this.label});
}

class _ContextOption extends _UiOption {
  final IconData icon;
  final Color iconColor;

  const _ContextOption({
    required super.key,
    required super.label,
    required this.icon,
    required this.iconColor,
  });
}

class _DurationPreset {
  final String label;
  final int minutes;

  const _DurationPreset({required this.label, required this.minutes});
}

const _symptomOptions = [
  _UiOption(key: 'headache', label: 'Headache'),
  _UiOption(key: 'nausea', label: 'Nausea'),
  _UiOption(key: 'fatigue', label: 'Fatigue'),
  _UiOption(key: 'dizziness', label: 'Dizziness'),
  _UiOption(key: 'anxiety', label: 'Anxiety'),
  _UiOption(key: 'brain_fog', label: 'Brain Fog'),
];

const _contextOptions = [
  _ContextOption(
    key: 'stress',
    label: 'Stress',
    icon: Icons.local_florist_rounded,
    iconColor: Color(0xFF87E6EF),
  ),
  _ContextOption(
    key: 'poor_sleep',
    label: 'Poor Sleep',
    icon: Icons.nightlight_round,
    iconColor: Color(0xFF87E6EF),
  ),
  _ContextOption(
    key: 'dehydration',
    label: 'Dehydration',
    icon: Icons.water_drop_rounded,
    iconColor: Color(0xFFA9C7FF),
  ),
  _ContextOption(
    key: 'heavy_meal',
    label: 'Heavy Meal',
    icon: Icons.restaurant_rounded,
    iconColor: Color(0xFFD6B2F7),
  ),
];

const _durationPresets = [
  _DurationPreset(label: '< 30m', minutes: 30),
  _DurationPreset(label: '1h', minutes: 60),
  _DurationPreset(label: '4h', minutes: 240),
  _DurationPreset(label: 'All Day', minutes: 720),
];
