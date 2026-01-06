import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/item_card.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../item_details/item_detail_screen.dart';
import '../main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ScrollController _quickLinksController;
  late final AnimationController _quickLinksHintController;
  bool _showQuickLinksHint = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quickLinksController = ScrollController();
    _quickLinksController.addListener(_handleQuickLinksScroll);
    _quickLinksHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().updateLocationDistrict(force: true);
      if (!mounted) return;
      if (_quickLinksController.hasClients &&
          _quickLinksController.position.maxScrollExtent <= 0) {
        setState(() {
          _showQuickLinksHint = false;
        });
        _quickLinksHintController.stop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quickLinksController.dispose();
    _quickLinksHintController.dispose();
    super.dispose();
  }

  void _handleQuickLinksScroll() {
    if (!_showQuickLinksHint) return;
    if (_quickLinksController.position.pixels <= 8) return;
    setState(() {
      _showQuickLinksHint = false;
    });
    _quickLinksHintController.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().updateLocationDistrict(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isUpdatingLocation = authProvider.isUpdatingLocation;
    final locationLabel =
        (isUpdatingLocation && authProvider.locationDistrict == 'Unknown')
            ? 'Detecting...'
            : authProvider.locationDistrict;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nearbyItems =
        itemsProvider.getNearbyItems(authProvider.locationDistrict, 4);
    final featuredItems = itemsProvider.getFeaturedItems(6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom Green Header
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primary, // Primary Green
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to JiranLink',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share tools, skills & services with your neighbors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isUpdatingLocation) ...[
                              const SizedBox(width: 6),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await context
                              .read<AuthProvider>()
                              .updateLocationDistrict(force: true);
                          if (!mounted) return;
                          final error =
                              context.read<AuthProvider>().locationError;
                          if (error != null && error.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                        child: const Text(
                          'Detect Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search for items or services...',
                        hintStyle:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Color(0xFF9CA3AF), size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: true,
                      ),
                      onChanged: (query) {
                        itemsProvider.setSearchQuery(query);
                      },
                      onSubmitted: (query) {
                        itemsProvider.setSearchQuery(query);
                        MainNavigation.of(context)?.switchToTab(1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Links
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _quickLinksController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCategoryItem(context,
                                Icons.inventory_2_outlined, 'All', null),
                            const SizedBox(width: 16),
                            _buildCategoryItem(context,
                                Icons.construction_outlined, 'Tools', ItemCategory.tools),
                            const SizedBox(width: 16),
                            _buildCategoryItem(context, Icons.devices_outlined,
                                'Appliances', ItemCategory.appliances),
                            const SizedBox(width: 16),
                            _buildCategoryItem(context, Icons.lightbulb_outline,
                                'Skills', ItemCategory.skills),
                            const SizedBox(width: 16),
                            _buildCategoryItem(
                                context,
                                Icons.business_center_outlined,
                                'Services',
                                ItemCategory.services),
                            const SizedBox(width: 16),
                            _buildCategoryItem(context, Icons.settings_outlined,
                                'Others', ItemCategory.others),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showQuickLinksHint ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Swipe',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedBuilder(
                                      animation: _quickLinksHintController,
                                      builder: (context, child) {
                                        final offset = 4 *
                                            _quickLinksHintController.value;
                                        return Transform.translate(
                                          offset: Offset(offset, 0),
                                          child: child,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Nearby Items
          if (nearbyItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Near You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        MainNavigation.of(context)?.switchToTab(1);
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = nearbyItems[index];
                    return ItemCard(
                      item: item,
                      isFavorite: favoritesProvider.isFavorite(item.id),
                      onToggleFavorite: () {
                        favoritesProvider.toggleFavorite(item.id);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                  childCount: nearbyItems.length > 4 ? 4 : nearbyItems.length,
                ),
              ),
            ),
          ],

          // Featured Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      MainNavigation.of(context)?.switchToTab(1);
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = featuredItems[index];
                  return ItemCard(
                    item: item,
                    isFavorite: favoritesProvider.isFavorite(item.id),
                    onToggleFavorite: () {
                      favoritesProvider.toggleFavorite(item.id);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(item: item),
                        ),
                      );
                    },
                  );
                },
                childCount: featuredItems.length,
              ),
            ),
          ),

          // Kampung Spirit Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 32, 16, 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reviving the Kampung Spirit 🏡',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'JiranLink connects neighbors to share resources, save money, and build a stronger community. Borrow what you need, share what you have.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildTrustBadge('Verified Users'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Secure Payments'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Local Community'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    IconData icon,
    String label,
    ItemCategory? category,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<ItemsProvider>().setCategory(category);
        MainNavigation.of(context)?.switchToTab(1);
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 12, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}
