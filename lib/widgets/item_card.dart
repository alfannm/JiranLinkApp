import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SECTION (Fixed Height Ratio)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3, // Keeps image nice and standard
                    child: CachedNetworkImage(
                      imageUrl: item.images.isNotEmpty 
                          ? item.images.first 
                          : 'https://placehold.co/400x300/png', // Fallback image
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: onToggleFavorite,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Type Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type == ItemType.hire
                          ? 'Hire'
                          : item.type == ItemType.borrow
                              ? 'Borrow'
                              : 'Rent',
                      style: const TextStyle(
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
                        color: Color(0xFF1F2937),
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
                        const Icon(Icons.location_on, size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 2),
                        Expanded( // Prevents text from pushing off screen
                          child: Text(
                            item.district,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price/Deposit & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.type == ItemType.borrow
                                    ? 'Borrow'
                                    : item.getPriceLabel(),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
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
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              item.rating != null
                                  ? item.rating!.toStringAsFixed(1)
                                  : 'New',
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }
}
