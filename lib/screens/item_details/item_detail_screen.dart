import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';

import '../messages/chat_screen.dart';
import '../bookings/booking_request_screen.dart';
import '../post_item/post_item_screen.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';

// Item detail screen with photos and actions.
class ItemDetailScreen extends StatefulWidget {
  final Item item;
  final String? heroTag;

  const ItemDetailScreen({
    super.key,
    required this.item,
    this.heroTag,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

// State for image carousel and selections.
class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _currentImageIndex = 0;

  // Opens a full screen image viewer.
  void _openFullScreenImage(List<String> images, int initialIndex) {
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
            child: images.length > 1
                ? CarouselSlider(
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                      initialPage: initialIndex,
                    ),
                    items: images.map((imageUrl) {
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
                      imageUrl: images.isNotEmpty
                          ? images.first
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

  // Builds the item detail layout.
  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final item = itemsProvider.getItemById(widget.item.id) ?? widget.item;
    final owner = item.owner;
    final heroTag = widget.heroTag ?? 'item-image-${item.id}';
    final favorites = context.watch<FavoritesProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final isOwner = currentUser != null &&
        (owner.id == currentUser.id ||
            (currentUser.email.isNotEmpty &&
                owner.email.isNotEmpty &&
                owner.email == currentUser.email));
    final isBorrow = item.type == ItemType.borrow;
    final landmarkText =
        item.landmark != null && item.landmark!.isNotEmpty ? item.landmark! : 'N/A';
    final expectedAvailableDate = item.expectedAvailableDate;
    final showExpectedAvailable =
        !item.available && expectedAvailableDate != null;
    final availabilityNote = showExpectedAvailable
        ? 'Expected back on ${dateFormat.format(expectedAvailableDate)}.'
        : 'Message the owner to reserve it for later.';
    final reserveMessage = showExpectedAvailable
        ? 'Hi ${owner.name}, I am interested in "${item.title}". I saw it is unavailable right now. If it is expected back on ${dateFormat.format(expectedAvailableDate)}, could you reserve it for me? Thanks!'
        : 'Hi ${owner.name}, I am interested in "${item.title}". It is unavailable right now. Could you reserve it for me when it is available? Thanks!';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Photo header.
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
                          onTap: () =>
                              _openFullScreenImage(item.images, _currentImageIndex),
                          child: Hero(
                            tag: heroTag,
                            child: item.images.length > 1
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
                                    items: item.images.map((imageUrl) {
                                      return Builder(
                                        builder: (BuildContext context) {
                                          return CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                Container(color: AppTheme.muted),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: item.images.isNotEmpty
                                        ? item.images.first
                                        : 'https://placehold.co/1200x800/png',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(color: AppTheme.muted),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                          ),
                        ),
                        // Gradient overlay for the header.
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
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Carousel indicator.
                        if (item.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: item.images
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
                                    color: Colors.white.withValues(alpha: 
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
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back,
                      color: AppTheme.foreground),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    favorites.toggleFavorite(item.id);
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      favorites.isFavorite(item.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favorites.isFavorite(item.id)
                          ? Colors.red
                          : AppTheme.foreground,
                    ),
                  ),
                ),
              ],
            ),

            // Details content.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item summary.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTypeChip(item),
                                const SizedBox(width: 6),
                                _buildStatusChip(item.available),
                              ],
                            ),
                            if (showExpectedAvailable) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Expected available date: ${dateFormat.format(expectedAvailableDate)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isBorrow)
                          Text(
                            item.getPriceLabel(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        if (item.deposit != null)
                          Text(
                            'Deposit: RM${item.deposit!.toInt()}',
                            style: const TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppTheme.mutedForeground),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.address.isNotEmpty
                                ? item.address
                                : '${item.district}, ${item.state}',
                            style: const TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 32),

                    // Item description.
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
                      item.description,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const Divider(height: 32),

                    // Item details.
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Category',
                            _capitalize(item.category
                                .toString()
                                .split('.')
                                .last),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            'Condition',
                            _formatCondition(item.condition),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Posted',
                            '${item.postedDate.month}/${item.postedDate.day}/${item.postedDate.year}',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            'Landmark',
                            landmarkText,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Owner profile.
                    const Text(
                      'Owner',
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
                        color: AppTheme.cardBackground,
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
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14,
                                        color: AppTheme.mutedForeground),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        owner.district,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mutedForeground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppTheme.mutedForeground),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Joined ${owner.joinDate.month}/${owner.joinDate.day}/${owner.joinDate.year}',
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
                          if (!isOwner)
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: owner.id,
                                      otherUserName: owner.name,
                                      otherUserAvatar: owner.avatar,
                                      item: item,
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
                    const Divider(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentSoftBorder),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: AppTheme.accentLeaf),
                              SizedBox(width: 8),
                              Text(
                                'Safety Tips',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentDeep,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('- Meet in a safe, public location if possible',
                              style: TextStyle(color: AppTheme.accentMid)),
                          SizedBox(height: 4),
                          Text('- Inspect the item before making payment',
                              style: TextStyle(color: AppTheme.accentMid)),
                          SizedBox(height: 4),
                          Text('- Use JiranLink\'s secure payment system',
                              style: TextStyle(color: AppTheme.accentMid)),
                          SizedBox(height: 4),
                          Text('- Report any suspicious activity',
                              style: TextStyle(color: AppTheme.accentMid)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadow,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: isOwner
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primary),
                        ),
                        onPressed: () async {
                          final updated = await navigator.push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PostItemScreen(existingItem: item),
                            ),
                          );
                          if (!mounted) return;
                          if (updated == true) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Listing updated.')),
                            );
                          }
                        },
                        child: const Text('Edit Listing'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.destructive,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete listing?'),
                              content: const Text(
                                  'This will remove your listing permanently.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.destructive,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          await itemsProvider.deleteItem(item);
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Listing deleted.')),
                          );
                          navigator.pop();
                        },
                        child: const Text('Delete Listing'),
                      ),
                    ),
                  ],
                )
              : item.available
                  ? Row(
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
                                    item: item,
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
                              final sent = await navigator.push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => BookingRequestScreen(
                                    item: item,
                                    borrower: currentUser,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              if (sent == true) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Request sent to owner.')),
                                );
                              }
                            },
                            child: Text(_actionLabel(item.type)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Currently unavailable. $availabilityNote',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: owner.id,
                                    otherUserName: owner.name,
                                    otherUserAvatar: owner.avatar,
                                    item: item,
                                    initialMessage: reserveMessage,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Chat to Reserve'),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // Returns the action label based on listing type.
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

  // Builds the type chip.
  Widget _buildTypeChip(Item item) {
    final label = _typeLabel(item).toUpperCase();
    final color = _typeAccent(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Builds the availability chip.
  Widget _buildStatusChip(bool available) {
    final color = available ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        available ? 'AVAILABLE' : 'UNAVAILABLE',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Builds a label and value pair.
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Capitalizes a single word.
  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  // Formats condition for display.
  String _formatCondition(ItemCondition? condition) {
    if (condition == null) return 'N/A';
    switch (condition) {
      case ItemCondition.newItem:
        return 'New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
    }
  }

  // Returns a readable type label.
  String _typeLabel(Item item) {
    if ((item.category == ItemCategory.services ||
            item.category == ItemCategory.skills) &&
        item.type == ItemType.rent) {
      return 'Job';
    }
    switch (item.type) {
      case ItemType.borrow:
        return 'Borrow';
      case ItemType.hire:
        return 'Hire';
      case ItemType.rent:
        return 'Rent';
    }
  }

  // Returns the accent color for an item type.
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
}
