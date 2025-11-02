import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  static const Color mainBlue = ui.Color.fromARGB(255, 249, 250, 251);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();

  String? _avatarUrl;
  Uint8List? _newAvatarBytes;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchManagerProfile();
  }

  Future<void> _fetchManagerProfile() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    try {
      // Prefer auth_user_id to locate the manager row
      final data = await sb
          .from('managers')
          .select('first_name, last_name, phone, department, avatar_url, email')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      // If not found via auth_user_id, try email as a fallback.
      final row =
          data ??
          await sb
              .from('managers')
              .select(
                'first_name, last_name, phone, department, avatar_url, email',
              )
              .eq('email', user.email ?? '')
              .maybeSingle();

      if (row == null) {
        // Initialize fields with auth info
        _nameController.text = '';
        _emailController.text = user.email ?? '';
        _phoneController.text = '';
        _deptController.text = '';
        _avatarUrl = null;
      } else {
        _nameController.text =
            '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim();
        _emailController.text = (row['email'] ?? user.email ?? '').toString();
        _phoneController.text = (row['phone'] ?? '').toString();
        _deptController.text = (row['department'] ?? '').toString();
        _avatarUrl = (row['avatar_url'] as String?);
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (imageFile == null) return;

    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(image: File(imageFile.path)),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || croppedBytes == null) return;
    setState(() => _newAvatarBytes = croppedBytes);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please sign in.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? newImageUrl;

    // 1) Upload avatar if newly picked
    if (_newAvatarBytes != null) {
      try {
        const ext = 'png';
        final fileName = '${user.id}/manager_profile.$ext';
        final ts = DateTime.now().millisecondsSinceEpoch;

        // Remove previous file to avoid stale cache issues
        await sb.storage.from('avatars').remove([fileName]);

        await sb.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              _newAvatarBytes!,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );

        final baseUrl = sb.storage.from('avatars').getPublicUrl(fileName);
        newImageUrl = '$baseUrl?t=$ts';
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading avatar: $e')));
        return;
      }
    }

    // 2) Update text fields in managers table
    final fullName = _nameController.text.trim();
    final parts = fullName.split(' ');
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = _phoneController.text.trim();
    final dept = _deptController.text.trim();

    final updates = <String, dynamic>{
      'first_name': first,
      'last_name': last,
      'phone': phone,
      'department': dept,
      if (newImageUrl != null)
        'avatar_url': newImageUrl, // requires text column
    };

    try {
      // Upsert by auth_user_id so the row exists even if it didn’t before
      await sb.from('managers').upsert({
        'auth_user_id': user.id,
        'email': user.email, // keep in sync
        ...updates,
      }, onConflict: 'auth_user_id');

      if (!mounted) return;
      setState(() {
        if (newImageUrl != null) {
          _avatarUrl = newImageUrl;
          _newAvatarBytes = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? bgImage;
    if (_newAvatarBytes != null) {
      bgImage = MemoryImage(_newAvatarBytes!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      bgImage = NetworkImage(_avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: mainBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: bgImage,
                            child: bgImage == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: mainBlue,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: _pickAvatar,
                                tooltip: 'Change photo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Full Name cannot be empty.';
                        }
                        if (!v.trim().contains(' ')) {
                          return 'Please enter both first and last name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        fillColor: Theme.of(
                          context,
                        ).disabledColor.withOpacity(0.1),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _deptController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Reuse your existing CropScreen from the customer file,
/// or keep this here if you want it self-contained.
class CropScreen extends StatefulWidget {
  final File image;
  const CropScreen({super.key, required this.image});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = CropController(
    aspectRatio: 1,
    defaultCrop: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Picture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final ui.Image cropped = await _controller.croppedBitmap();
              final byteData = await cropped.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final bytes = byteData?.buffer.asUint8List();
              if (mounted && bytes != null) Navigator.pop(context, bytes);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CropImage(
            controller: _controller,
            image: Image.file(widget.image),
            gridColor: Colors.white70,
            gridCornerSize: 50,
            gridThinWidth: 2,
            gridThickWidth: 4,
            scrimColor: Colors.black54,
            alwaysShowThirdLines: true,
          ),
        ),
      ),
    );
  }
}
