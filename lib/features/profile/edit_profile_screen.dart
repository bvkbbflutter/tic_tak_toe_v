import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../services/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _countryController;
  late TextEditingController _customPhotoUrlController;
  String _selectedGender = 'Prefer not to say';
  String _selectedPhotoUrl = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).value;
    _displayNameController = TextEditingController(text: profile?.displayName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _countryController = TextEditingController(text: profile?.country ?? '');
    _customPhotoUrlController = TextEditingController(text: profile?.photoUrl ?? '');
    _selectedGender = profile?.gender ?? 'Prefer not to say';
    _selectedPhotoUrl = profile?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _customPhotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile = profile.copyWith(
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        country: _countryController.text.trim(),
        gender: _selectedGender,
        photoUrl: _selectedPhotoUrl.isNotEmpty
            ? _selectedPhotoUrl
            : _customPhotoUrlController.text.trim(),
      );

      await ref.read(profileServiceProvider).updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Preview
                  Center(
                    child: Column(
                      children: [
                        AppAvatar(
                          photoUrl: _selectedPhotoUrl.isNotEmpty
                              ? _selectedPhotoUrl
                              : _customPhotoUrlController.text.trim(),
                          name: _displayNameController.text.isNotEmpty
                              ? _displayNameController.text
                              : 'Player',
                          radius: 46,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Choose an Avatar (Web & Mobile Compatible)",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preset Avatars list
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.presetAvatars.length,
                      itemBuilder: (context, index) {
                        final avatarUrl = AppConstants.presetAvatars[index];
                        final isSelected = _selectedPhotoUrl == avatarUrl;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotoUrl = avatarUrl;
                              _customPhotoUrlController.text = avatarUrl;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.deepPurple : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: AppAvatar(
                              photoUrl: avatarUrl,
                              name: 'A$index',
                              radius: 26,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display Name
                  _buildTextField(
                    controller: _displayNameController,
                    label: "Display Name",
                    icon: Icons.person,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Name required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  _buildTextField(
                    controller: _usernameController,
                    label: "Username",
                    icon: Icons.alternate_email,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Username required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Gender Selection
                  const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: AppTheme.neumorphicBox(context, borderRadius: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        items: AppConstants.genderOptions.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  _buildTextField(
                    controller: _bioController,
                    label: "Bio / About Me",
                    icon: Icons.info_outline,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Country
                  _buildTextField(
                    controller: _countryController,
                    label: "Country",
                    icon: Icons.public,
                  ),
                  const SizedBox(height: 16),

                  // Custom Photo URL
                  _buildTextField(
                    controller: _customPhotoUrlController,
                    label: "Custom Photo URL (optional)",
                    icon: Icons.link,
                    onChanged: (v) => setState(() => _selectedPhotoUrl = v),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  GestureDetector(
                    onTap: _isSaving ? null : _handleSave,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: AppTheme.neumorphicBox(context, borderRadius: 16),
                      alignment: Alignment.center,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: AppTheme.neumorphicBox(context, borderRadius: 12),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(icon, size: 20, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
