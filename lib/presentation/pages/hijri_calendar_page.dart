import 'package:flutter/material.dart';

import '../../core/utils/hijri_utils.dart';

/// An interactive full-month Hijri calendar page with month navigation,
/// Gregorian mapping, today highlight, and Islamic observances/fasting indicators.
class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late DateTime _today;
  late HijriCalendarMonth _currentMonth;
  late HijriCalendarCell _selectedCell;

  @override
  void initState() {
    super.initState();
    _today = widget.initialDate ?? DateTime.now();
    _currentMonth = HijriCalendarMonth.fromDate(_today, today: _today);
    _selectedCell = _findInitialCell();
  }

  HijriCalendarCell _findInitialCell() {
    for (final cell in _currentMonth.cells) {
      if (cell.isToday && cell.isCurrentMonth) {
        return cell;
      }
    }
    // Fallback to first day of current month
    for (final cell in _currentMonth.cells) {
      if (cell.isCurrentMonth) return cell;
    }
    return _currentMonth.cells.first;
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _today = now;
      _currentMonth = HijriCalendarMonth.fromDate(now, today: now);
      _selectedCell = _findInitialCell();
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = _currentMonth.previousMonth(_today);
      _selectedCell = _findFirstDayOfCurrentMonth();
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = _currentMonth.nextMonth(_today);
      _selectedCell = _findFirstDayOfCurrentMonth();
    });
  }

  HijriCalendarCell _findFirstDayOfCurrentMonth() {
    for (final cell in _currentMonth.cells) {
      if (cell.isToday && cell.isCurrentMonth) return cell;
    }
    for (final cell in _currentMonth.cells) {
      if (cell.isCurrentMonth) return cell;
    }
    return _currentMonth.cells.first;
  }

  void _onCellTapped(HijriCalendarCell cell) {
    setState(() {
      _selectedCell = cell;
      // If user tapped a padding cell from another month, navigate to that month
      if (!cell.isCurrentMonth) {
        _currentMonth = HijriCalendarMonth.fromHijri(
          cell.hijriYear,
          cell.hijriMonth,
          today: _today,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Hijriah'),
        actions: [
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_outlined, size: 18),
            label: const Text('Hari Ini'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              _goToNextMonth();
            } else if (details.primaryVelocity! > 200) {
              _goToPreviousMonth();
            }
          },
          child: Column(
            children: [
              _buildMonthNavigator(theme, scheme),
              const SizedBox(height: 8),
              _buildWeekdayHeader(theme, scheme),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCalendarGrid(theme, scheme),
                    const SizedBox(height: 16),
                    _buildSelectedDateCard(theme, scheme),
                    const SizedBox(height: 12),
                    _buildLegendCard(theme, scheme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(ThemeData theme, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan Sebelumnya',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _goToPreviousMonth,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentMonth.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentMonth.gregorianRangeLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bulan Berikutnya',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(7, (index) {
          final isFriday = index == 5; // Jum'at
          final isSunday = index == 0; // Ahad
          final labelColor = isFriday
              ? scheme.primary
              : isSunday
              ? scheme.error.withValues(alpha: 0.85)
              : scheme.onSurfaceVariant;

          return Expanded(
            child: Center(
              child: Text(
                hijriWeekdaysShort[index],
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, ColorScheme scheme) {
    final cells = _currentMonth.cells;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final cell = cells[index];
        final isSelected =
            cell.hijriDay == _selectedCell.hijriDay &&
            cell.hijriMonth == _selectedCell.hijriMonth &&
            cell.hijriYear == _selectedCell.hijriYear;

        return _CalendarCellWidget(
          key: ValueKey('hijri_cell_${cell.hijriMonth}_${cell.hijriDay}'),
          cell: cell,
          isSelected: isSelected,
          onTap: () => _onCellTapped(cell),
        );
      },
    );
  }

  Widget _buildSelectedDateCard(ThemeData theme, ColorScheme scheme) {
    final cell = _selectedCell;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: cell.isToday
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cell.isToday
                        ? scheme.primary
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cell.isToday ? 'HARI INI' : cell.weekdayName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: cell.isToday
                          ? scheme.onPrimary
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (cell.isSunnahFasting) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sunnah Puasa',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${cell.weekdayName}, ${cell.fullHijriLabel}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cell.gregorianFormatted,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (cell.observance != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 18,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cell.observance!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem(
            color: scheme.primary,
            label: 'Hari ini',
            theme: theme,
          ),
          _buildLegendItem(
            color: const Color(0xFFD4AF37),
            label: 'Puasa Sunnah / Hari Penting',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CalendarCellWidget extends StatelessWidget {
  const _CalendarCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.onTap,
  });

  final HijriCalendarCell cell;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isToday = cell.isToday;
    final isCurrent = cell.isCurrentMonth;

    // Background decoration
    BoxDecoration decoration;
    if (isToday) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary, width: 1.5),
      );
    } else {
      decoration = BoxDecoration(
        color: isCurrent
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? scheme.outlineVariant.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      );
    }

    // Text colors
    final hijriTextColor = isToday
        ? scheme.onPrimary
        : isCurrent
        ? scheme.onSurface
        : scheme.onSurfaceVariant.withValues(alpha: 0.35);

    final gregorianTextColor = isToday
        ? scheme.onPrimary.withValues(alpha: 0.8)
        : isCurrent
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cell.hijriDay.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: 16,
                  color: hijriTextColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                cell.gregorianDayString,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: gregorianTextColor,
                ),
              ),
              const SizedBox(height: 2),
              // Indicator dot
              if (cell.isSunnahFasting || cell.observance != null)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isToday ? scheme.onPrimary : const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
