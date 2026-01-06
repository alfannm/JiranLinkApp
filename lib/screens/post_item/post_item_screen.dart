import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/items_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/item.dart';
import '../../services/location_service.dart';

// State and district options for the location form.
const Map<String, List<String>> malaysiaLocations = {
  "Johor": ["Batu Pahat", "Johor Bahru", "Kluang", "Kota Tinggi", "Kulai", "Mersing", "Muar", "Pontian", "Segamat", "Tangkak"],
  "Kedah": ["Baling", "Bandar Baharu", "Kota Setar", "Kuala Muda", "Kubang Pasu", "Kulim", "Langkawi", "Padang Terap", "Pendang", "Pokok Sena", "Sik", "Yan"],
  "Kelantan": ["Bachok", "Gua Musang", "Jeli", "Kota Bharu", "Kuala Krai", "Machang", "Pasir Mas", "Pasir Puteh", "Tanah Merah", "Tumpat"],
  "Melaka": ["Alor Gajah", "Jasin", "Melaka Tengah"],
  "Negeri Sembilan": ["Jelebu", "Jempol", "Kuala Pilah", "Port Dickson", "Rembau", "Seremban", "Tampin"],
  "Pahang": ["Bentong", "Bera", "Cameron Highlands", "Jerantut", "Kuantan", "Lipis", "Maran", "Pekan", "Raub", "Rompin", "Temerloh"],
  "Perak": ["Bagan Datuk", "Batang Padang", "Hilir Perak", "Hulu Perak", "Kampar", "Kerian", "Kinta", "Kuala Kangsar", "Larut, Matang dan Selama", "Manjung", "Muallim", "Perak Tengah"],
  "Perlis": ["Perlis"],
  "Pulau Pinang": ["Barat Daya", "Seberang Perai Selatan", "Seberang Perai Tengah", "Seberang Perai Utara", "Timur Laut"],
  "Sabah": ["Beaufort", "Beluran", "Keningau", "Kinabatangan", "Kota Belud", "Kota Kinabalu", "Kota Marudu", "Kuala Penyu", "Kudat", "Kunak", "Lahad Datu", "Nabawan", "Papar", "Penampang", "Pitas", "Putatan", "Ranau", "Sandakan", "Semporna", "Sipitang", "Tambunan", "Tawau", "Telupid", "Tenom", "Tongod", "Tuaran"],
  "Sarawak": ["Betong", "Bintulu", "Kapit", "Kuching", "Limbang", "Miri", "Mukah", "Samarahan", "Sarikei", "Serian", "Sibu", "Sri Aman"],
  "Selangor": ["Gombak", "Hulu Langat", "Hulu Selangor", "Klang", "Kuala Langat", "Kuala Selangor", "Petaling", "Sabak Bernam", "Sepang"],
  "Terengganu": ["Besut", "Dungun", "Hulu Terengganu", "Kemaman", "Kuala Nerus", "Kuala Terengganu", "Marang", "Setiu"],
  "Wilayah Persekutuan": ["Kuala Lumpur", "Labuan", "Putrajaya"]
};

// Screen for creating or editing a listing.
class PostItemScreen extends StatefulWidget {
  final Item? existingItem;

  const PostItemScreen({super.key, this.existingItem});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

// State for the listing form, photos, and location.
class _PostItemScreenState extends State<PostItemScreen> {
  static const int _maxPhotos = 5;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();

  final List<XFile> _images = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;

  ItemCategory _selectedCategory = ItemCategory.tools;
  ItemType _selectedType = ItemType.rent;
  PriceUnit _selectedPriceUnit = PriceUnit.day;
  ItemCondition _selectedCondition = ItemCondition.good;

  String? _selectedState;
  String? _selectedDistrict;
  String? _autoDetectedState;
  String? _autoDetectedDistrict;

  // True when editing an existing item.
  bool get _isEditing => widget.existingItem != null;
  // Total number of photos selected or existing.
  int get _totalImages => _existingImageUrls.length + _images.length;
  // True when more photos can be added.
  bool get _canAddMorePhotos => _totalImages < _maxPhotos;

  // Capitalizes the first character of a label.
  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  // Builds an image widget for web or mobile.
  Widget _buildImage(
    XFile image, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (kIsWeb) {
      return Image.network(
        image.path,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return Image.file(
      File(image.path),
      width: width,
      height: height,
      fit: fit,
    );
  }

  // Tile that opens the photo picker.
  Widget _buildAddPhotoTile({double size = 120}) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_upload_outlined, color: AppTheme.mutedForeground),
            SizedBox(height: 6),
            Text(
              'Upload photos',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            ),
            Text(
              'Up to 5',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Shows a full screen preview for a picked image.
  Future<void> _showImagePreview(XFile image) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Image preview',
      barrierDismissible: true,
      barrierColor: Colors.black87,
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildImage(image, fit: BoxFit.contain),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Alerts the user when the photo limit is reached.
  void _showPhotoLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can add up to 5 photos.')),
    );
  }

  // Picks multiple images from the gallery.
  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    if (!mounted) return;
    if (files.isEmpty) return;

    final remaining = _maxPhotos - _totalImages;
    if (remaining <= 0) {
      _showPhotoLimitMessage();
      return;
    }

    final selected = files.take(remaining).toList();
    if (files.length > remaining) {
      _showPhotoLimitMessage();
    }

    setState(() {
      _images.addAll(selected);
    });
  }

  // Captures a photo from the camera.
  Future<void> _takePhoto() async {
    if (_totalImages >= _maxPhotos) {
      _showPhotoLimitMessage();
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      _images.add(file);
    });
  }

  // Shows a bottom sheet to choose photo source.
  Future<void> _showImageSourceSheet() async {
    if (_totalImages >= _maxPhotos) {
      _showPhotoLimitMessage();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                iconColor: Colors.white,
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                iconColor: Colors.white,
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Shows a full screen preview for a network image.
  Future<void> _showNetworkImagePreview(String imageUrl) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Image preview',
      barrierDismissible: true,
      barrierColor: Colors.black87,
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Initializes form values when editing.
  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item == null) return;

    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _priceController.text = item.price.toStringAsFixed(0);
    if (item.deposit != null) {
      _depositController.text = item.deposit!.toStringAsFixed(0);
    }
    _addressController.text = item.address;
    if (item.landmark != null) {
      _landmarkController.text = item.landmark!;
    }
    _selectedCategory = item.category;
    _selectedType = item.type;
    _selectedPriceUnit = item.priceUnit;
    _selectedCondition = item.condition ?? ItemCondition.good;
    _selectedState = item.state;
    _selectedDistrict = item.district;
    _latitude = item.latitude;
    _longitude = item.longitude;
    _existingImageUrls.addAll(item.images);
  }

  // Disposes text controllers.
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  // Uses device location to fill state and district.
  Future<void> _detectLocation() async {
    try {
      // Read the current position.
      final pos = await _locationService.getCurrentPosition();

      // Look up address details for the position.
      final placemark = await _locationService.getPlacemarkFromPosition(pos);
      
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        
        if (placemark != null) {
          // Choose a state name from the placemark.
          final detectedState = placemark.administrativeArea?.trim();
          if (detectedState != null && detectedState.isNotEmpty) {
            final matchedKey = malaysiaLocations.keys.firstWhere(
              (k) => detectedState.contains(k),
              orElse: () => '',
            );
            if (matchedKey.isNotEmpty) {
              _selectedState = matchedKey;
              _autoDetectedState = null;
            } else {
              _selectedState = detectedState;
              _autoDetectedState = detectedState;
            }
          } else {
            _selectedState = null;
            _autoDetectedState = null;
          }

          // Choose a district name from the placemark.
          final candidateDistrict = _locationService.getDistrictFromPlacemark(placemark);

          if (candidateDistrict.isNotEmpty) {
            _selectedDistrict = candidateDistrict;
            _autoDetectedDistrict = candidateDistrict;
          } else {
            _selectedDistrict = null;
            _autoDetectedDistrict = null;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location and address detected.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect location. Check permissions.')),
      );
    }
  }

  // Validates and submits the listing.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final itemsProvider = context.read<ItemsProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;

    if (_totalImages == 0) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }

    if (currentUser == null) return;
    final existingItem = widget.existingItem;
    if (_isEditing && existingItem != null) {
      final ownerMatches = existingItem.owner.id == currentUser.id ||
          (currentUser.email.isNotEmpty &&
              existingItem.owner.email.isNotEmpty &&
              existingItem.owner.email == currentUser.email);
      if (!ownerMatches) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('You can only edit your own listings.')),
        );
        return;
      }
    }

    if (_selectedState == null || _selectedDistrict == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select state and district.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (_latitude == null || _longitude == null) {
      // Best-effort location lookup when missing.
      try {
        final pos = await _locationService.getCurrentPosition();
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      } catch (e) {
      }
    }

    // Calculate price and deposit values.
    double finalPrice = 0;
    double? finalDeposit;

    if (_selectedType == ItemType.rent) {
      finalPrice = double.tryParse(_priceController.text) ?? 0;
      finalDeposit = _depositController.text.isNotEmpty
          ? double.tryParse(_depositController.text)
          : null;
    } else if (_selectedType == ItemType.borrow) {
      finalPrice = 0;
      finalDeposit = _depositController.text.isNotEmpty
          ? double.tryParse(_depositController.text)
          : null;
    } else if (_selectedType == ItemType.hire) {
      finalPrice = double.tryParse(_priceController.text) ?? 0;
      finalDeposit = null;
    }

    try {
      final isServiceCategory = _selectedCategory == ItemCategory.skills ||
          _selectedCategory == ItemCategory.services;
      final updatedItem = Item(
        id: existingItem?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        price: finalPrice,
        deposit: finalDeposit,
        priceUnit: _selectedPriceUnit,
        images: _existingImageUrls,
        owner: currentUser,
        district: _selectedDistrict!,
        state: _selectedState!,
        address: _addressController.text.trim(),
        landmark: _landmarkController.text.trim().isNotEmpty
            ? _landmarkController.text.trim()
            : null,
        latitude: _latitude ?? existingItem?.latitude ?? 0,
        longitude: _longitude ?? existingItem?.longitude ?? 0,
        available: existingItem?.available ?? true,
        expectedAvailableDate: existingItem?.expectedAvailableDate,
        condition: isServiceCategory ? null : _selectedCondition,
        postedDate: existingItem?.postedDate ?? DateTime.now(),
        views: existingItem?.views ?? 0,
      );

      if (_isEditing) {
        await itemsProvider.updateItem(
              item: updatedItem,
              newImages: _images,
              existingImageUrls: _existingImageUrls,
            );
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Listing updated successfully!')),
        );
      } else {
        await itemsProvider.createItem(
              item: updatedItem,
              images: _images,
            );
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Item posted successfully!')),
        );
      }
      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Failed to update item: $e' : 'Failed to post item: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Builds the listing form UI.
  @override
  Widget build(BuildContext context) {
    // Derived display flags.
    final isServiceCategory = _selectedCategory == ItemCategory.skills ||
        _selectedCategory == ItemCategory.services;
    final showPrice = isServiceCategory ||
        _selectedType == ItemType.rent ||
        _selectedType == ItemType.hire;
    final showDeposit = !isServiceCategory &&
        (_selectedType == ItemType.rent || _selectedType == ItemType.borrow);
    final showPer = isServiceCategory || (showPrice && _selectedType != ItemType.borrow);
    final typeOptions = isServiceCategory
        ? [ItemType.rent]
        : ItemType.values.where((type) => type != ItemType.hire).toList();
    final stateOptions = List<String>.from(malaysiaLocations.keys);
    if (_autoDetectedState != null &&
        _autoDetectedState!.isNotEmpty &&
        !stateOptions.contains(_autoDetectedState)) {
      stateOptions.insert(0, _autoDetectedState!);
    }
    final districtOptions = _selectedState != null
        ? List<String>.from(malaysiaLocations[_selectedState] ?? <String>[])
        : <String>[];
    if (_autoDetectedDistrict != null &&
        _autoDetectedDistrict!.isNotEmpty &&
        !districtOptions.contains(_autoDetectedDistrict)) {
      districtOptions.insert(0, _autoDetectedDistrict!);
    }
    const double singleImageSize = 120.0;
    const double imageListPadding = 8.0;
    final hasImages = _totalImages > 0;
    final imageBoxHeight =
        hasImages ? (singleImageSize + (imageListPadding * 2)) : 200.0;
    final canAddMorePhotos = _canAddMorePhotos;
    final existingImageCount = _existingImageUrls.length;
    final totalImageCount = existingImageCount + _images.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Post Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker.
              !hasImages
                  ? GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        height: imageBoxHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.border, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 48, color: AppTheme.mutedForeground),
                            SizedBox(height: 8),
                            Text(
                              'Add Photos (up to 5)',
                              style: TextStyle(color: AppTheme.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      height: imageBoxHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.border, style: BorderStyle.solid),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(imageListPadding),
                          itemBuilder: (context, index) {
                            if (canAddMorePhotos && index == totalImageCount) {
                              return _buildAddPhotoTile(size: singleImageSize);
                            }
                            final isExisting = index < existingImageCount;
                            final imageIndex =
                                isExisting ? index : index - existingImageCount;
                            final imageWidget = isExisting
                                ? Image.network(
                                    _existingImageUrls[imageIndex],
                                    width: singleImageSize,
                                    height: singleImageSize,
                                    fit: BoxFit.cover,
                                  )
                                : _buildImage(
                                    _images[imageIndex],
                                    width: singleImageSize,
                                    height: singleImageSize,
                                  );
                            final onPreview = isExisting
                                ? () => _showNetworkImagePreview(
                                      _existingImageUrls[imageIndex],
                                    )
                                : () => _showImagePreview(_images[imageIndex]);

                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: onPreview,
                                  child: SizedBox.square(
                                    dimension: singleImageSize,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageWidget,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isExisting) {
                                          _existingImageUrls.removeAt(imageIndex);
                                        } else {
                                          _images.removeAt(imageIndex);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: totalImageCount + (canAddMorePhotos ? 1 : 0),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Title field.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Cordless Drill',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field.
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your item...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category and type selection.
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ItemCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: ItemCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            _capitalizeFirst(
                              category.toString().split('.').last,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            return;
                          }
                          _selectedCategory = value;
                          final isService = value == ItemCategory.skills ||
                              value == ItemCategory.services;
                          if (isService) {
                            _selectedType = ItemType.rent;
                          } else if (_selectedType == ItemType.hire) {
                            _selectedType = ItemType.rent;
                          }
                        });
                      },
                    ),
                  ),
                  if (!isServiceCategory) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<ItemType>(
                        initialValue: typeOptions.contains(_selectedType)
                            ? _selectedType
                            : typeOptions.first,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: typeOptions.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              _capitalizeFirst(
                                type.toString().split('.').last,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              _selectedType = value;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              if (!isServiceCategory) ...[
                // Condition selection.
                DropdownButtonFormField<ItemCondition>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(),
                  ),
                  items: ItemCondition.values.map((condition) {
                    // Friendly condition label.
                    String label = '';
                    switch (condition) {
                      case ItemCondition.newItem: label = 'New'; break;
                      case ItemCondition.likeNew: label = 'Like New'; break;
                      case ItemCondition.good: label = 'Good'; break;
                      case ItemCondition.fair: label = 'Fair'; break;
                    }
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCondition = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Price and unit.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPrice)
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (RM)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (showPrice && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  if (showPrice) const SizedBox(width: 16),
                  if (showPer)
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<PriceUnit>(
                        initialValue: _selectedPriceUnit,
                        decoration: const InputDecoration(
                          labelText: 'Per',
                          border: OutlineInputBorder(),
                        ),
                        items: PriceUnit.values.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              _capitalizeFirst(
                                unit.toString().split('.').last,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriceUnit = value!;
                          });
                        },
                      ),
                    ),
                ],
              ),
              if (showDeposit) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Security Deposit (RM)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    // Require a deposit when shown.
                    if (showDeposit && (value == null || value.isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text("Location Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // State and district.
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedState,
                      hint: const Text('State'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      ),
                      items: stateOptions.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedDistrict = null;
                          _autoDetectedState = null;
                          _autoDetectedDistrict = null;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedDistrict,
                      hint: const Text('District'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      ),
                      items: districtOptions
                          .map((district) {
                            return DropdownMenuItem(
                              value: district,
                              child: Text(district, overflow: TextOverflow.ellipsis),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                          _autoDetectedDistrict = null;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Use current location button.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use current location (Auto-detect State/District)'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address field.
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  hintText: 'e.g. Unit No, Street Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Landmark field.
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark (Optional)',
                  hintText: 'e.g. Near Petronas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Submit action.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Post Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
