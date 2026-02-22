import 'package:flutter/material.dart';

/// Base shimmer animation for skeleton loaders
class ShimmerSkeleton extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerSkeleton({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerPosition,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _shimmerPosition.value - 0.3,
                _shimmerPosition.value,
                _shimmerPosition.value + 0.3,
              ],
              colors: [
                Colors.grey[700]!,
                Colors.grey[500]!,
                Colors.grey[700]!,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton avatar (circular placeholder)
class SkeletonAvatar extends StatelessWidget {
  final double radius;
  final EdgeInsets margin;

  const SkeletonAvatar({
    super.key,
    this.radius = 24,
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        margin: margin,
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton text line (rectangular placeholder)
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets margin;
  final BorderRadius borderRadius;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    BorderRadius? borderRadius,
  }) : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton tile (list item placeholder)
class SkeletonTile extends StatelessWidget {
  final bool showAvatar;
  final int textLines;
  final EdgeInsets padding;

  const SkeletonTile({
    super.key,
    this.showAvatar = true,
    this.textLines = 2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        children: [
          if (showAvatar) ...const [
            SkeletonAvatar(radius: 20),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line
                const SkeletonText(
                  width: 200,
                  height: 14,
                  margin: EdgeInsets.only(bottom: 8),
                ),
                // Subtitle lines
                ...List.generate(
                  textLines - 1,
                  (index) => SkeletonText(
                    height: 12,
                    width: index == textLines - 2 ? 150 : double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton card (room/event card placeholder)
class SkeletonCard extends StatelessWidget {
  final EdgeInsets padding;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        margin: padding,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonText(
                    width: 200,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  // Subtitle
                  SkeletonText(
                    width: 150,
                    height: 12,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  // Description (2 lines)
                  SkeletonText(
                    height: 12,
                    margin: EdgeInsets.only(bottom: 4),
                  ),
                  SkeletonText(
                    width: 180,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton bubble (chat message placeholder)
class SkeletonBubble extends StatelessWidget {
  final bool isUserMessage;
  final EdgeInsets padding;

  const SkeletonBubble({
    super.key,
    this.isUserMessage = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ShimmerSkeleton(
        child: Container(
          margin: padding,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(
                width: 180,
                height: 12,
                margin: EdgeInsets.only(bottom: 4),
              ),
              SkeletonText(
                width: 150,
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton profile header
class SkeletonProfileHeader extends StatelessWidget {
  final EdgeInsets padding;

  const SkeletonProfileHeader({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton(
      child: Column(
        children: [
          // Avatar
          SkeletonAvatar(radius: 40, margin: EdgeInsets.only(bottom: 12)),
          // Display name
          SkeletonText(
            width: 200,
            height: 18,
            margin: EdgeInsets.only(bottom: 8),
          ),
          // Bio
          SkeletonText(
            width: 250,
            height: 12,
            margin: EdgeInsets.only(bottom: 16),
          ),
          // Stats row (3 items)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SkeletonText(width: 40, height: 14),
                    SkeletonText(width: 60, height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SkeletonText(width: 40, height: 14),
                    SkeletonText(width: 60, height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SkeletonText(width: 40, height: 14),
                    SkeletonText(width: 60, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton list (multiple tiles)
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool showAvatar;
  final EdgeInsets itemPadding;

  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.showAvatar = true,
    this.itemPadding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonTile(
        showAvatar: showAvatar,
        padding: itemPadding,
      ),
    );
  }
}

/// Skeleton grid (multiple cards)
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final EdgeInsets padding;

  const SkeletonGrid({
    super.key,
    this.itemCount = 4,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(padding: padding),
    );
  }
}
