import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  String? _avatarUrl;
  Uint8List? _newAvatarBytes;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeProfile();
  }

  Future<void> _fetchEmployeeProfile() async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    try {
      // Prefer locating by auth_user_id; fallback to email.
      Map<String, dynamic>? row = await sb
          .from('employees')
          .select('first_name, last_name, phone, role, avatar_url, email')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      row ??= await sb
          .from('employees')
          .select('first_name, last_name, phone, role, avatar_url, email')
          .eq('email', user.email ?? '')
          .maybeSingle();

      if (!mounted) return;

      if (row == null) {
        _nameCtrl.text = '';
        _emailCtrl.text = user.email ?? '';
        _phoneCtrl.text = '';
        _roleCtrl.text = '';
        _avatarUrl = null;
      } else {
        _nameCtrl.text = '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'
            .trim();
        _emailCtrl.text = (row['email'] ?? user.email ?? '').toString();
        _phoneCtrl.text = (row['phone'] ?? '').toString();
        _roleCtrl.text = (row['role'] ?? '').toString();
        _avatarUrl = row['avatar_url'] as String?;
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    final Uint8List? cropped = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (_) => CropScreen(image: File(picked.path)),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || cropped == null) return;
    setState(() => _newAvatarBytes = cropped);
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

    setState(() => _saving = true);

    String? newImageUrl;

    // 1) Upload avatar if needed
    if (_newAvatarBytes != null) {
      try {
        const ext = 'png';
        final path = '${user.id}/employee_profile.$ext';
        final ts = DateTime.now().millisecondsSinceEpoch;

        // Remove previous file to avoid stale cache
        await sb.storage.from('avatars').remove([path]);

        await sb.storage
            .from('avatars')
            .uploadBinary(
              path,
              _newAvatarBytes!,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );

        final baseUrl = sb.storage.from('avatars').getPublicUrl(path);
        newImageUrl = '$baseUrl?t=$ts';
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading avatar: $e')));
        return;
      }
    }

    // 2) Upsert text fields
    final full = _nameCtrl.text.trim();
    final parts = full.split(' ');
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = _phoneCtrl.text.trim();
    final role = _roleCtrl.text.trim();

    final updates = <String, dynamic>{
      'first_name': first,
      'last_name': last,
      'phone': phone,
      'role': role.isEmpty ? 'employee' : role,
      if (newImageUrl != null) 'avatar_url': newImageUrl, // needs text column
    };

    try {
      await sb.from('employees').upsert({
        'auth_user_id': user.id,
        'email': user.email, // keep synced
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
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
      body: _loading
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
                      controller: _nameCtrl,
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
                      controller: _emailCtrl,
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
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextFormField(
                      controller: _roleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _saving
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

/// Reusable crop screen
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
              final ui.Image img = await _controller.croppedBitmap();
              final data = await img.toByteData(format: ui.ImageByteFormat.png);
              final bytes = data?.buffer.asUint8List();
              if (mounted && bytes != null)
                Navigator.pop<Uint8List>(context, bytes);
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
