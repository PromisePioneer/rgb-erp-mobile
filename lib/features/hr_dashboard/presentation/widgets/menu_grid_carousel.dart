import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import 'menu_grid_item.dart';

/// Menu grid carousel - paginated menu grid like myBCA
class MenuGridCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> menuItems;
  final int itemsPerPage;

  const MenuGridCarousel({
    super.key,
    required this.menuItems,
    this.itemsPerPage = 8,
  });

  @override
  State<MenuGridCarousel> createState() => _MenuGridCarouselState();
}

class _MenuGridCarouselState extends State<MenuGridCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int get _pageCount => (widget.menuItems.length / widget.itemsPerPage).ceil();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menu items in paged grid
        SizedBox(
          height: 220, // Fixed height for 2 rows of items (adjusted for larger icons)
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pageCount,
            itemBuilder: (context, pageIndex) {
              // Calculate start and end index for this page
              final startIndex = pageIndex * widget.itemsPerPage;
              final endIndex = (startIndex + widget.itemsPerPage)
                  .clamp(0, widget.menuItems.length);
              final pageItems = widget.menuItems.sublist(startIndex, endIndex);

              return _buildPageGrid(pageItems);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Page indicators - exactly like banner_carousel.dart pattern
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pageCount,
            (index) => AnimatedContainer(
              duration: AppConstants.animationFast,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.slate300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageGrid(List<Map<String, dynamic>> pageItems) {
    // Use LayoutBuilder to get available width and distribute evenly across 4 columns
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / 4;

        // Build 2 rows x 4 columns grid
        final rows = <Widget>[];

        // Split items into rows (4 items per row)
        for (var i = 0; i < pageItems.length; i += 4) {
          final rowItems = pageItems.sublist(
            i,
            (i + 4).clamp(0, pageItems.length),
          );

          // Pad to exactly 4 items per row to maintain consistent column positions
          while (rowItems.length < 4) {
            rowItems.add(<String, dynamic>{});
          }

          rows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: rowItems.map<Widget>((item) {
                  // Empty placeholder for missing slots - maintains column position
                  if (item.isEmpty) {
                    return SizedBox(width: slotWidth);
                  }
                  return SizedBox(
                    width: slotWidth,
                    child: MenuGridItem(
                      label: item['label'] as String,
                      icon: item['icon'] as IconData,
                      bg: item['bg'] as Color,
                      fg: item['fg'] as Color,
                      badge: item['badge'] as String?,
                      onTap: () {
                        final route = item['route'] as String?;
                        if (route != null) {
                          context.push(route);
                        } else if (item['label'] == 'Patroli') {
                          context.push('/patrol');
                        } else if (item['label'] == 'Lapor Pelanggaran') {
                          context.push('/violation-report/form');
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }

        return Column(
          children: rows,
        );
      },
    );
  }
}
