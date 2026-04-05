import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/unsplash_service.dart';
import '../../core/models/skill_model.dart';
import '../../main.dart' show categories;

class AddSkillScreen extends StatefulWidget {
  final bool isOffered;
  final OfferedSkill? initialOfferedSkill;
  final WantedSkill? initialWantedSkill;

  const AddSkillScreen({
    super.key,
    required this.isOffered,
    this.initialOfferedSkill,
    this.initialWantedSkill,
  });

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _learningPointsController = TextEditingController();

  String _selectedCategory = 'Programming';
  String _selectedLevel = 'Beginner';
  bool _isLoading = false;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  bool get _isEditMode =>
      widget.initialOfferedSkill != null || widget.initialWantedSkill != null;

  @override
  void initState() {
    super.initState();
    _prefillForm();
  }

  void _prefillForm() {
    if (widget.isOffered && widget.initialOfferedSkill != null) {
      final skill = widget.initialOfferedSkill!;
      _nameController.text = skill.name;
      _aboutController.text = skill.about;
      _learningPointsController.text = skill.learningPoints.join('\n');
      _selectedCategory = skill.category;
      _selectedLevel = skill.level;
      return;
    }

    if (!widget.isOffered && widget.initialWantedSkill != null) {
      final skill = widget.initialWantedSkill!;
      _nameController.text = skill.name;
      _aboutController.text = skill.remarks;
      _learningPointsController.text = skill.otherRelevantSkills.join(', ');
      if (skill.category.isNotEmpty) {
        _selectedCategory = skill.category;
      }
      _selectedLevel = skill.level;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _learningPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            _isEditMode
                ? (widget.isOffered
                    ? 'Edit Offered Skill'
                    : 'Edit Wanted Skill')
                : (widget.isOffered ? 'Offer a Skill' : 'Request a Skill'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(widget.isOffered
                  ? 'Skill Details'
                  : 'What do you want to learn?'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Skill Name',
                hint: widget.isOffered
                    ? 'e.g. Flutter Development'
                    : 'e.g. Piano Lessons',
                icon: Icons.school_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a skill name';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Category',
                value: _selectedCategory,
                items: categories.where((c) => c != 'All').toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Skill Level',
                value: _selectedLevel,
                items: _levels,
                onChanged: (val) => setState(() => _selectedLevel = val!),
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _aboutController,
                label: widget.isOffered
                    ? 'About this skill'
                    : 'Remarks / Requirements',
                hint: widget.isOffered
                    ? 'Describe what you can teach...'
                    : 'Any specific language or focus area?',
                icon: Icons.info_outline,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please provide some details';
                  }
                  if (v.trim().length < 10) {
                    return 'At least 10 characters required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _learningPointsController,
                label: widget.isOffered
                    ? 'What they will learn (one per line)'
                    : 'Other relevant skills you know',
                hint: widget.isOffered
                    ? 'Widget tree\nState management\nFirebase'
                    : 'Java, SQL, etc.',
                icon: widget.isOffered ? Icons.list : Icons.extension_outlined,
                maxLines: 3,
                validator: widget.isOffered
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Add at least one learning point';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode
                              ? 'Save Changes'
                              : (widget.isOffered
                                  ? 'Post Skill'
                                  : 'Submit Request'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (widget.isOffered) {
        final profile = await _firestoreService.getUserProfile();

        String? imageUrl = widget.initialOfferedSkill?.imageUrl;
        if (!_isEditMode || imageUrl == null || imageUrl.isEmpty) {
          final unsplashService = UnsplashService();
          imageUrl = await unsplashService.getSkillImage(
            _nameController.text.trim(),
            _selectedCategory,
          );
        }

        final userName = profile?.name ?? user.displayName ?? 'Anonymous';
        final skill = OfferedSkill(
          id: widget.initialOfferedSkill?.id ?? '',
          userId: user.uid,
          userName: userName,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          level: _selectedLevel,
          about: _aboutController.text.trim(),
          learningPoints: _learningPointsController.text
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          imageUrl: imageUrl,
        );
        if (_isEditMode) {
          await _firestoreService.updateOfferedSkill(skill);
        } else {
          await _firestoreService.addOfferedSkill(skill);
        }
      } else {
        final unsplashService = UnsplashService();
        final refreshedImage = await unsplashService.getSkillImage(
          _nameController.text.trim(),
          _selectedCategory,
        );
        final imageUrl = refreshedImage ?? widget.initialWantedSkill?.imageUrl;

        final skill = WantedSkill(
          id: widget.initialWantedSkill?.id ?? '',
          userId: user.uid,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          level: _selectedLevel,
          remarks: _aboutController.text.trim(),
          otherRelevantSkills: _learningPointsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          imageUrl: imageUrl,
        );
        if (_isEditMode) {
          await _firestoreService.updateWantedSkill(skill);
        } else {
          await _firestoreService.addWantedSkill(skill);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Skill updated successfully!'
                  : (widget.isOffered ? 'Skill added!' : 'Request submitted!'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        await NotificationService().showLocalNotification(
          title: _isEditMode
              ? 'Skill Updated'
              : (widget.isOffered ? 'Skill Posted' : 'Learning Request Added'),
          body: _isEditMode
              ? 'Your changes to "${_nameController.text}" were saved.'
              : (widget.isOffered
                  ? 'Your skill "${_nameController.text}" is now live for swapping.'
                  : 'Your interest in "${_nameController.text}" has been recorded.'),
          payload: 'my_skills',
        );

        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }
}
