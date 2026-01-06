import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart' as app;
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

// Screen for editing user profile details.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

// State for profile form and avatar upload.
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  XFile? _selectedAvatar;
  String? _currentAvatarUrl;

  // Loads current user data into the form.
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _currentAvatarUrl = user.avatar;
    }
  }

  // Disposes text controllers.
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Saves profile changes to Firestore.
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      String? avatarUrl = _currentAvatarUrl;
      if (_selectedAvatar != null) {
        setState(() {
          _isUploadingAvatar = true;
        });
        avatarUrl = await _uploadAvatar(user.id, _selectedAvatar!);
      }
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'avatar': avatarUrl,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingAvatar = false;
        });
      }
    }
  }

  // Builds the edit profile layout.
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(user),
              const SizedBox(height: 24),
              const Divider(height: 32),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _buildReadOnlyField('Email', user.email),
              const SizedBox(height: 16),
              _buildReadOnlyField('District', user.district),
              const SizedBox(height: 8),
              const Text(
                'District is updated automatically based on your location.',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Uploads a new avatar and returns its URL.
  Future<String?> _uploadAvatar(String userId, XFile file) async {
    final bytes = await file.readAsBytes();
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  // Picks an avatar from the given source.
  Future<void> _pickAvatar(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (!mounted || file == null) return;
    setState(() {
      _selectedAvatar = file;
    });
  }

  // Clears the selected avatar.
  void _removeAvatar() {
    setState(() {
      _selectedAvatar = null;
      _currentAvatarUrl = null;
    });
  }

  // Shows the avatar source selection sheet.
  Future<void> _showAvatarSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
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
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              if (_selectedAvatar != null ||
                  (_currentAvatarUrl != null &&
                      _currentAvatarUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppTheme.destructive),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: AppTheme.destructive),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Resolves the avatar image to display.
  ImageProvider? _resolveAvatarImage() {
    if (_selectedAvatar != null) {
      if (kIsWeb) {
        return NetworkImage(_selectedAvatar!.path);
      }
      return FileImage(File(_selectedAvatar!.path));
    }
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl!);
    }
    return null;
  }

  // Builds the avatar preview and controls.
  Widget _buildAvatarSection(app.User user) {
    final avatarImage = _resolveAvatarImage();
    final fallbackLetter =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final hasAvatar = avatarImage != null;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.muted,
                backgroundImage: avatarImage,
                child: hasAvatar
                    ? null
                    : Text(
                        fallbackLetter,
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isSaving ? null : _showAvatarSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (_isUploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _showAvatarSourceSheet,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Change Photo'),
          ),
          if (hasAvatar)
            TextButton(
              onPressed: _isSaving ? null : _removeAvatar,
              child: const Text(
                'Remove Photo',
                style: TextStyle(color: AppTheme.destructive),
              ),
            ),
        ],
      ),
    );
  }

  // Builds a read-only form field.
  Widget _buildReadOnlyField(String label, String value) {
    final displayValue = value.isNotEmpty ? value : 'Not set';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.mutedForeground),
        border: const OutlineInputBorder(),
      ),
      child: Text(
        displayValue,
        style: TextStyle(
          color: value.isNotEmpty
              ? AppTheme.foreground
              : AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
