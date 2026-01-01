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

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _addressController = TextEditingController();

  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;

  ItemCategory _selectedCategory = ItemCategory.tools;
  ItemType _selectedType = ItemType.rent;
  PriceUnit _selectedPriceUnit = PriceUnit.day;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    if (!mounted) return;
    if (files.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(files);
    });
  }

  Future<void> _detectLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect location. Check permissions.')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    if (_latitude == null || _longitude == null) {
      await _detectLocation();
    }

    final newItem = Item(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      type: _selectedType,
      price: double.parse(_priceController.text),
      deposit: _depositController.text.isNotEmpty
          ? double.parse(_depositController.text)
          : null,
      priceUnit: _selectedPriceUnit,
      images: const [],
      owner: currentUser,
      district: currentUser.district,
      address: _addressController.text.trim(),
      latitude: _latitude ?? 0,
      longitude: _longitude ?? 0,
      available: true,
      condition: ItemCondition.good,
      postedDate: DateTime.now(),
      views: 0,
      rating: null,
      reviewCount: 0,
    );

    try {
      await context.read<ItemsProvider>().createItem(
            item: newItem,
            images: _images,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item posted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post item: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Item'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Placeholder
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.border, style: BorderStyle.solid),
                  ),
                  child: _images.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 48, color: AppTheme.mutedForeground),
                            SizedBox(height: 8),
                            Text('Add Photos',
                                style: TextStyle(color: AppTheme.mutedForeground)),
                          ],
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final image = _images[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(
                                      image.path,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(image.path),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: _images.length,
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
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

              // Description
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

              // Category & Type Row
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
                          child: Text(category
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<ItemType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ItemType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                              type.toString().split('.').last.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Row
              Row(
                children: [
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
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
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
                          child: Text(unit.toString().split('.').last),
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
              const SizedBox(height: 16),

              // Deposit
              TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Security Deposit (Optional)',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. SS2, Petaling Jaya',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use current location'),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
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
                      : const Text(
                          'Post Item',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
