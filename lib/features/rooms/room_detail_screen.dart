import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/room.dart';
import '../bookings/widgets/slot_grid.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.room});
  final Room room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _showTimes = false;

  int? _selectedStartSlotIdx; // inclusive
  int? _selectedEndSlotIdx; // exclusive

  static const int _maxSlots = 6; // 3h max (6 * 30min)

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final startHour = room.openHourStart ?? 6;
    final endHour = room.openHourEnd ?? 23;

    final selection = _selectionSummary(
      context: context,
      day: _selectedDay,
      startHour: startHour,
      startIndex: _selectedStartSlotIdx,
      endIndex: _selectedEndSlotIdx,
    );
    final priceInfo = _priceSummary(
      priceCentsPerHour: room.priceCents,
      startIndex: _selectedStartSlotIdx,
      endIndex: _selectedEndSlotIdx,
    );
    final canBook = selection != null && priceInfo != null;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _HeaderImages(
                photos: room.photos,
                title: room.name,
                neighborhood: room.neighborhood,
                rating: room.rating,
                priceCents: room.priceCents,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((room.description ?? '').isNotEmpty)
                        Text(room.description!, style: text.bodyMedium),
                      const SizedBox(height: 12),
                        SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                          if ((room.neighborhood ?? '').isNotEmpty)
                            Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              avatar: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              ),
                              label: Text(room.neighborhood!),
                              visualDensity: VisualDensity.compact,
                            ),
                            ),
                          if (room.capacity != null)
                            Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              avatar: const Icon(
                              Icons.group_outlined,
                              size: 18,
                              ),
                              label: Text('${room.capacity} people'),
                              visualDensity: VisualDensity.compact,
                            ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text(
                              '${startHour.toString().padLeft(2, '0')}:00 – ${endHour.toString().padLeft(2, '0')}:00',
                            ),
                            visualDensity: VisualDensity.compact,
                            ),
                          ),
                          ],
                        ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Amenities',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AmenitiesChips(facilities: room.facilities),

                      const SizedBox(height: 16),
                      Text(
                        'Pick a date',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calendar → Times
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SizeTransition(
                            sizeFactor: anim,
                            axisAlignment: -1,
                            child: child,
                          ),
                        ),
                        child: _showTimes
                            ? _TimesSection(
                                key: const ValueKey('times'),
                                selectedDay: _selectedDay,
                                start: startHour,
                                end: endHour,
                                startIndex: _selectedStartSlotIdx,
                                endIndex: _selectedEndSlotIdx,
                                maxSlots: _maxSlots,
                                onSelectionChanged: (s, e, clamped) {
                                  if (clamped) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Maximum booking length is 3 hours.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: scheme.inverseSurface,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _selectedStartSlotIdx = s;
                                    _selectedEndSlotIdx = e;
                                  });
                                },
                                onBack: () =>
                                    setState(() => _showTimes = false),
                                onClear: () => setState(() {
                                  _selectedStartSlotIdx = null;
                                  _selectedEndSlotIdx = null;
                                }),
                              )
                            : _CalendarCard(
                                key: const ValueKey('calendar'),
                                initialFocused: _focusedDay,
                                selectedDay: _selectedDay,
                                onSelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = DateTime(
                                      selectedDay.year,
                                      selectedDay.month,
                                      selectedDay.day,
                                    );
                                    _focusedDay = focusedDay;
                                    _showTimes = true;
                                  });
                                },
                              ),
                      ),

                      const SizedBox(
                        height: 120,
                      ), // space so content doesn't hide behind the bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // IMPORTANT: use Positioned to avoid full-screen overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BookingBar(
              selectionText: selection?.label,
              priceText: priceInfo?.label,
              enabled: canBook,
              onClear: () {
                setState(() {
                  _selectedStartSlotIdx = null;
                  _selectedEndSlotIdx = null;
                });
              },
              onBook: () {
                final info = _finalBookingInfo(
                  day: _selectedDay,
                  startHour: startHour,
                  startIndex: _selectedStartSlotIdx!,
                  endIndex: _selectedEndSlotIdx!,
                  priceCentsPerHour: room.priceCents,
                );
                debugPrint('[BOOK] $info');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booked: $info'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- helpers ----------

  _SelectionLabel? _selectionSummary({
    required BuildContext context,
    required DateTime day,
    required int startHour,
    required int? startIndex,
    required int? endIndex,
  }) {
    if (startIndex == null || endIndex == null || endIndex == startIndex)
      return null;
    final start = _indexToTimeOfDay(startHour, startIndex);
    final end = _indexToTimeOfDay(startHour, endIndex);
    final hours = (endIndex - startIndex).abs() / 2.0;
    final dateLabel = _dayLabel(day);
    final range = '${start.format(context)}–${end.format(context)}';
    final dur =
        '${hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1)}h';
    return _SelectionLabel('$dateLabel • $range • $dur');
  }

  _PriceLabel? _priceSummary({
    required int? priceCentsPerHour,
    required int? startIndex,
    required int? endIndex,
  }) {
    if (priceCentsPerHour == null ||
        startIndex == null ||
        endIndex == null ||
        endIndex == startIndex)
      return null;
    final hours = (endIndex - startIndex).abs() / 2.0;
    final euros = (priceCentsPerHour * hours) / 100.0;
    return _PriceLabel('€${euros.toStringAsFixed(2)}');
  }

  String _finalBookingInfo({
    required DateTime day,
    required int startHour,
    required int startIndex,
    required int endIndex,
    required int? priceCentsPerHour,
  }) {
    final startTod = _indexToTimeOfDay(startHour, startIndex);
    final endTod = _indexToTimeOfDay(startHour, endIndex);
    final startDt = DateTime(
      day.year,
      day.month,
      day.day,
      startTod.hour,
      startTod.minute,
    );
    final endDt = DateTime(
      day.year,
      day.month,
      day.day,
      endTod.hour,
      endTod.minute,
    );
    final hours = (endIndex - startIndex).abs() / 2.0;
    final euros = priceCentsPerHour == null
        ? 0
        : (priceCentsPerHour * hours) / 100.0;
    return '${_dayLabel(day)} • ${_fmt(startDt)}–${_fmt(endDt)} • ${hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1)}h • €${euros.toStringAsFixed(2)}';
  }

  String _dayLabel(DateTime d) =>
      '${_wday[d.weekday]}, ${_mon[d.month]} ${d.day}';
  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  TimeOfDay _indexToTimeOfDay(int startHour, int index) {
    final hour = startHour + (index ~/ 2);
    final minute = (index % 2) * 30;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

// ---- header, grid, calendar (unchanged) ----

class _HeaderImages extends StatelessWidget {
  const _HeaderImages({
    required this.photos,
    required this.title,
    required this.neighborhood,
    required this.rating,
    required this.priceCents,
  });

  final List<String> photos;
  final String title;
  final String? neighborhood;
  final double? rating;
  final int? priceCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      // OPAQUE when collapsed
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      // small elevation tint when scrolled under
      scrolledUnderElevation: 2,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Collapse factor (0 expanded → 1 collapsed)
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final t = settings == null
              ? 0.0
              : ((1.0 -
                        (settings.currentExtent - settings.minExtent) /
                            (settings.maxExtent - settings.minExtent)))
                    .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // image
              PageView.builder(
                itemCount: photos.isNotEmpty ? photos.length : 1,
                controller: PageController(viewportFraction: 1.0),
                itemBuilder: (context, index) {
                  final photo = photos.isNotEmpty ? photos[index] : null;
                  return photo != null
                      ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                      : Container(color: scheme.surfaceContainerHighest);
                },
              ),
              // scrim for legibility
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.35),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Title shown only when expanded (fade out as it collapses)
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: IgnorePointer(
                  ignoring: t > 0.6,
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // BADGES in a SafeArea at top-right (never under the notch / clock)
              Positioned(
                right: 12,
                top: MediaQuery.of(context).padding.top + 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rating != null)
                      _Pill(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        label: rating!.toStringAsFixed(1),
                        bg: scheme.surface.withOpacity(0.85),
                        fg: scheme.onSurface,
                      ),
                    const SizedBox(width: 8),
                    if (priceCents != null)
                      _Pill(
                        icon: Icons.euro_rounded,
                        label: '${(priceCents! / 100).toStringAsFixed(0)}/h',
                        bg: scheme.primary,
                        fg: scheme.onPrimary,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmenitiesChips extends StatelessWidget {
  const _AmenitiesChips({required this.facilities});
  final List<String> facilities;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final tileWidth = (maxWidth / 2) - 6; // Subtract spacing
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: facilities
              .map(
                (f) => SizedBox(
                  width: tileWidth,
                  child: _AmenityTile(label: f),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    super.key,
    required this.initialFocused,
    required this.selectedDay,
    required this.onSelected,
  });

  final DateTime initialFocused;
  final DateTime selectedDay;
  final void Function(DateTime selected, DateTime focused) onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 120)),
        focusedDay: initialFocused,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onSelected,
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        availableGestures: AvailableGestures.horizontalSwipe,
      ),
    );
  }
}

class _TimesSection extends StatefulWidget {
  const _TimesSection({
    super.key,
    required this.selectedDay,
    required this.start,
    required this.end,
    required this.onSelectionChanged,
    required this.onBack,
    required this.onClear,
    required this.maxSlots,
    this.startIndex,
    this.endIndex,
  });

  final DateTime selectedDay;
  final int start;
  final int end;
  final int maxSlots;
  final int? startIndex;
  final int? endIndex;
  final void Function(int? startIndex, int? endIndex, bool clamped)
  onSelectionChanged;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  State<_TimesSection> createState() => _TimesSectionState();
}

class _TimesSectionState extends State<_TimesSection> {
  int? _startIdx;
  int? _endIdx;

  @override
  void initState() {
    super.initState();
    _startIdx = widget.startIndex;
    _endIdx = widget.endIndex;
  }

  void _handleTap(int index) {
    bool clamped = false;
    setState(() {
      if (_startIdx == null) {
        _startIdx = index;
        _endIdx = null;
      } else if (_endIdx == null) {
        final diff = (index - _startIdx!).abs();
        if (diff == 0) {
          _startIdx = null;
          _endIdx = null;
        } else if (diff > widget.maxSlots) {
          clamped = true;
          _endIdx = index > _startIdx!
              ? _startIdx! + widget.maxSlots
              : _startIdx! - widget.maxSlots;
        } else {
          _endIdx = index;
        }
      } else {
        _startIdx = index;
        _endIdx = null;
      }
      widget.onSelectionChanged(_startIdx, _endIdx, clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final slotsTotal = (widget.end - widget.start) * 2;
    final selectedSlots = (_startIdx != null && _endIdx != null)
        ? (_endIdx! - _startIdx!).abs()
        : (_startIdx != null ? 1 : 0);
    final progress = selectedSlots.clamp(0, widget.maxSlots) / widget.maxSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Change date',
              onPressed: widget.onBack,
            ),
            Text(
              'Available on ${widget.selectedDay.day}.${widget.selectedDay.month}.',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (_startIdx != null || _endIdx != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startIdx = null;
                    _endIdx = null;
                  });
                  widget.onClear();
                  widget.onSelectionChanged(null, null, false);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress == 0 ? null : progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceVariant.withOpacity(0.4),
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'max 3h',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SlotGrid(
          startHour: widget.start,
          endHour: widget.end,
          onTapIndex: _handleTap,
          selectedStartIndex: _startIdx,
          selectedEndIndex: _endIdx,
          columns: 4,
          compact: true,
          // If today, disable passed slots
          disabledIndices: _disabledTodayIndices(
            widget.selectedDay,
            widget.start,
            slotsTotal,
          ),
        ),
      ],
    );
  }

  Set<int> _disabledTodayIndices(
    DateTime selectedDay,
    int startHour,
    int slotsTotal,
  ) {
    final now = DateTime.now();
    final isSameDay =
        now.year == selectedDay.year &&
        now.month == selectedDay.month &&
        now.day == selectedDay.day;
    if (!isSameDay) return {};
    final currentIndex =
        ((now.hour - startHour) * 2) + (now.minute >= 30 ? 1 : 0);
    final disabled = <int>{};
    for (var i = 0; i <= currentIndex && i < slotsTotal; i++) {
      if (i >= 0) disabled.add(i);
    }
    return disabled;
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.selectionText,
    required this.priceText,
    required this.enabled,
    required this.onClear,
    required this.onBook,
  });

  final String? selectionText;
  final String? priceText;
  final bool enabled;
  final VoidCallback onClear;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        // Make it a true bar
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectionText ?? 'Select a date & time (max 3h)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectionText == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontWeight: selectionText == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (priceText != null)
                    Text(
                      priceText!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (selectionText != null)
              OutlinedButton(onPressed: onClear, child: const Text('Clear')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: enabled ? onBook : null,
              child: const Text('Book now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({required this.label});
  final String label;

  IconData _iconFor(String key) {
    final k = key.toLowerCase();
    if (k.contains('wifi')) return Icons.wifi;
    if (k.contains('light')) return Icons.light_mode_outlined;
    if (k.contains('mic') || k.contains('podcast')) return Icons.mic_none;
    if (k.contains('screen')) return Icons.display_settings_outlined;
    if (k.contains('whiteboard')) return Icons.border_color_outlined;
    if (k.contains('coffee')) return Icons.coffee_outlined;
    if (k.contains('backdrop')) return Icons.image_outlined;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(_iconFor(label), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.iconColor,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? fg),
              const SizedBox(width: 4),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

class _SelectionLabel {
  final String label;
  const _SelectionLabel(this.label);
}

class _PriceLabel {
  final String label;
  const _PriceLabel(this.label);
}

const _wday = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};
const _mon = {
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};
