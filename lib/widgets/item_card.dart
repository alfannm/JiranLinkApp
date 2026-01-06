import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  Color _typeAccent(Item item) {
    if ((item.category == ItemCategory.services ||
            item.category == ItemCategory.skills) &&
        item.type == ItemType.rent) {
      return AppTheme.accentTerracotta;
    }
    switch (item.type) {
      case ItemType.borrow:
        return AppTheme.accentTeal;
      case ItemType.hire:
        return AppTheme.accentOlive;
      case ItemType.rent:
        return AppTheme.accentAmber;
    }
  }

  String _typeLabel(Item item) {
    if ((item.category == ItemCategory.services ||
            item.category == ItemCategory.skills) &&
        item.type == ItemType.rent) {
      return 'Job';
    }
    switch (item.type) {
      case ItemType.hire:
        return 'Hire';
      case ItemType.borrow:
        return 'Borrow';
      case ItemType.rent:
        return 'Rent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final typeColor = _typeAccent(item);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE SECTION (Fixed Height Ratio)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 4 / 3, // Keeps image nice and standard
                      child: Hero(
                        tag: 'item-image-${item.id}',
                        child: CachedNetworkImage(
                          imageUrl: item.images.isNotEmpty
                              ? item.images.first
                              : 'https://placehold.co/400x300/png', // Fallback image
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.muted,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.muted,
                            child: const Icon(Icons.broken_image,
                                color: AppTheme.mutedForeground),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: widget.onToggleFavorite,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.cardBackground,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppTheme.shadow, blurRadius: 4)
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0)
                                  .animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey<bool>(widget.isFavorite),
                            color: widget.isFavorite
                                ? Colors.red
                                : AppTheme.mutedForeground,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Type Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel(item),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (!item.available)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: const Text(
                          'Unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 2. CONTENT SECTION (Flexible Height)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important!
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppTheme.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Location Row
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppTheme.mutedForeground),
                          const SizedBox(width: 2),
                          Expanded(
                            // Prevents text from pushing off screen
                            child: Text(
                              item.district,
                              style: const TextStyle(
                                color: AppTheme.mutedForeground,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Price/Deposit
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.type == ItemType.borrow
                                ? 'Borrow'
                                : item.getPriceLabel(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.deposit != null)
                            Text(
                              'Deposit RM${item.deposit!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.mutedForeground,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
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
