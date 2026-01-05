import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';

import '../messages/chat_screen.dart';
import '../bookings/booking_request_screen.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _currentImageIndex = 0;

  void _openFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: widget.item.images.length > 1
                ? CarouselSlider(
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                      initialPage: initialIndex,
                    ),
                    items: widget.item.images.map((imageUrl) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.white),
                        ),
                      );
                    }).toList(),
                  )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.item.images.isNotEmpty
                          ? widget.item.images.first
                          : 'https://placehold.co/1200x800/png',
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.item.owner;
    final favorites = context.watch<FavoritesProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar & Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => _openFullScreenImage(_currentImageIndex),
                          child: widget.item.images.length > 1
                              ? CarouselSlider(
                                  options: CarouselOptions(
                                    height: constraints.maxHeight,
                                    viewportFraction: 1.0,
                                    enableInfiniteScroll: false,
                                    autoPlay: false,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                  ),
                                  items: widget.item.images.map((imageUrl) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              Container(color: AppTheme.muted),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        );
                                      },
                                    );
                                  }).toList(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.item.images.isNotEmpty
                                      ? widget.item.images.first
                                      : 'https://placehold.co/1200x800/png',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: AppTheme.muted),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                        ),
                        // Gradient overlay for text readability
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Page Indicator
                        if (widget.item.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widget.item.images
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentImageIndex == entry.key ? 12.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                        _currentImageIndex == entry.key
                                            ? 0.9
                                            : 0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    favorites.isFavorite(widget.item.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: favorites.isFavorite(widget.item.id)
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () {
                    favorites.toggleFavorite(widget.item.id);
                  },
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type, Category & Condition Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.type
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.category
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.item.condition != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'CONDITION: ${widget.item.condition.toString().split('.').last.replaceAll('newItem', 'New').replaceAll('likeNew', 'Like New').replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}').toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    if (widget.item.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.item.rating} (${widget.item.reviewCount} reviews)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (widget.item.rating != null) const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppTheme.mutedForeground),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.address.isNotEmpty
                                    ? widget.item.address
                                    : '${widget.item.district}, ${widget.item.state}',
                                style: const TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 14,
                                ),
                              ),
                              if (widget.item.landmark != null &&
                                  widget.item.landmark!.isNotEmpty)
                                Text(
                                  'Near ${widget.item.landmark}',
                                  style: const TextStyle(
                                    color: AppTheme.mutedForeground,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Metadata
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.item.available
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.item.available ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: widget.item.available
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.item.postedDate.day}/${widget.item.postedDate.month}/${widget.item.postedDate.year}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price (Only if not borrow)
                    if (widget.item.type != ItemType.borrow)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Price',
                                      style: TextStyle(
                                        color: AppTheme.mutedForeground,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.item.getPriceLabel(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.item.deposit != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Security Deposit',
                                        style: TextStyle(
                                          color: AppTheme.mutedForeground,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'RM${widget.item.deposit!.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.foreground,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.description,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Owner Profile
                    const Text(
                      'Lender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: owner.avatar != null
                                ? NetworkImage(owner.avatar!)
                                : null,
                            backgroundColor: AppTheme.primary,
                            child: owner.avatar == null
                                ? Text(
                                    owner.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owner.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${owner.rating} (${owner.reviewCount} reviews)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: owner.id,
                                    otherUserName: owner.name,
                                    otherUserAvatar: owner.avatar,
                                    item: widget.item,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: owner.id,
                          otherUserName: owner.name,
                          otherUserAvatar: owner.avatar,
                          item: widget.item,
                        ),
                      ),
                    );
                  },
                  child: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (currentUser == null) return;
                    final sent = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingRequestScreen(
                          item: widget.item,
                          borrower: currentUser,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (sent == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request sent to owner.')),
                      );
                    }
                  },
                  child: Text(_actionLabel(widget.item.type)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabel(ItemType type) {
    switch (type) {
      case ItemType.borrow:
        return 'Borrow Now';
      case ItemType.hire:
        return 'Hire Now';
      case ItemType.rent:
        return 'Rent Now';
    }
  }
}
