import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../providers/schedule_provider.dart';

/// Horizontal scrollable date strip widget
class DateStrip extends StatefulWidget {
  const DateStrip({super.key});

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  late ScrollController _scrollController;

  // Generate dates: 7 days before today to 30 days after today
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();
    // Scroll to today after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _generateDates() {
    final today = DateTime.now();
    _dates = List.generate(
      37, // 7 before + 30 after = 37 days
      (index) => today.subtract(Duration(days: 7 - index)),
    );
  }

  void _scrollToToday() {
    // Find index of today
    final today = DateTime.now();
    final todayIndex = _dates.indexWhere((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);

    if (todayIndex != -1 && _scrollController.hasClients) {
      // Calculate offset to center today
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = 56.0; // width of each date item
      final offset = (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getDayName(DateTime date) {
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return dayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ScheduleNotifier>();
    final selectedDate = notifier.state.selectedDate;
    final schedules = notifier.state.schedules;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          // Check if this date has schedule
          final hasSchedule = schedules.any((item) =>
              item.date.year == date.year &&
              item.date.month == date.month &&
              item.date.day == date.day);

          return GestureDetector(
            onTap: () => notifier.selectDate(date),
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.slate200.withAlpha(77),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dot indicator for schedule
                  if (hasSchedule)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
