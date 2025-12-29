import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../providers/items_provider.dart';
import '../item_details/item_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final items = itemsProvider.items;

    final userLat = itemsProvider.userLatitude;
    final userLng = itemsProvider.userLongitude;

    final LatLng initialTarget;
    if (userLat != null && userLng != null) {
      initialTarget = LatLng(userLat, userLng);
    } else if (items.isNotEmpty) {
      initialTarget = LatLng(items.first.latitude, items.first.longitude);
    } else {
      // Fallback (Kuala Terengganu-ish)
      initialTarget = const LatLng(5.3290, 103.1370);
    }

    final markers = <Marker>{
      if (userLat != null && userLng != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(userLat, userLng),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      ...items.map((item) => _markerForItem(context, item)),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: 'Detect my location',
            onPressed: () async {
              final ok = await context.read<ItemsProvider>().detectAndSetUserLocation();
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not get your location. Check GPS + permissions.')),
                );
                return;
              }

              final lat = context.read<ItemsProvider>().userLatitude;
              final lng = context.read<ItemsProvider>().userLongitude;
              if (lat != null && lng != null) {
                await _controller?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
                );
              }
            },
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13),
        myLocationEnabled: userLat != null && userLng != null,
        myLocationButtonEnabled: false,
        markers: markers,
        onMapCreated: (c) => _controller = c,
      ),
    );
  }

  Marker _markerForItem(BuildContext context, Item item) {
    return Marker(
      markerId: MarkerId(item.id),
      position: LatLng(item.latitude, item.longitude),
      infoWindow: InfoWindow(
        title: item.title,
        snippet: item.district,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
          );
        },
      ),
    );
  }
}
