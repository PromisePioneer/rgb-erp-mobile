import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Banner carousel widget - reusable across features
class BannerCarousel extends StatefulWidget {
  /// List of image URLs or asset paths
  final List<String>? images;

  /// Banner height - defaults to 140 for login screen
  /// Use 180-200 for promo banners (myBCA style)
  final double height;

  /// Border radius for the banner
  final double borderRadius;

  /// Whether to show page indicators
  final bool showIndicators;

  const BannerCarousel({
    super.key,
    this.images,
    this.height = 140,
    this.borderRadius = 16,
    this.showIndicators = true,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Default banners (placeholder - replace with actual images)
  final List<String> _defaultImages = [
    'https://picsum.photos/400/150?random=1',
    'https://picsum.photos/400/150?random=2',
    'https://picsum.photos/400/150?random=3',
  ];

  List<String> get _images => widget.images ?? _defaultImages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final imageUrl = _images[index];
              final isNetworkImage = imageUrl.startsWith('http');

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: AppColors.slate200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: isNetworkImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.slate200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                ),
              );
            },
          ),
        ),
        if (widget.showIndicators) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _images.length,
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
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.white.withAlpha(179),
        ),
      ),
    );
  }
}
