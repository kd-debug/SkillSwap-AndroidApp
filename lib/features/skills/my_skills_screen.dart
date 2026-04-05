import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/skill_model.dart';
import '../../main.dart' show Skill, SkillDetailScreen;
import 'add_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isHydratingWantedImages = false;
  final Set<String> _hydratedWantedSkillIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Skills',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.teal,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(text: 'Offered Skills'),
              Tab(text: 'Wanted Skills'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOfferedSkillsList(),
            _buildWantedSkillsList(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddSkillOptions(context);
          },
          backgroundColor: Colors.teal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Skill', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showAddSkillOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to add?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.school, color: Colors.white),
              ),
              title: const Text('Offer a Skill'),
              subtitle: const Text('Teach others what you know'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSkillScreen(isOffered: true),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade400,
                child: const Icon(Icons.search, color: Colors.white),
              ),
              title: const Text('Request a Skill'),
              subtitle: const Text('Find someone to teach you'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSkillScreen(isOffered: false),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferedSkillsList() {
    return StreamBuilder<List<OfferedSkill>>(
      stream: _firestoreService.getMyOfferedSkills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final skills = snapshot.data ?? [];
        if (skills.isEmpty) {
          return _buildEmptyState(
              'You haven\'t offered any skills yet.', Icons.school_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            final skill = skills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () => _openOfferedSkillDetails(skill),
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: skill.imageUrl != null
                      ? NetworkImage(skill.imageUrl!)
                      : null,
                  child: skill.imageUrl == null
                      ? const Icon(Icons.book, color: Colors.teal)
                      : null,
                ),
                title: Text(skill.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${skill.category} • ${skill.level}\n${skill.about}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit skill',
                      icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                      onPressed: () => _openEditOfferedSkill(skill),
                    ),
                    IconButton(
                      tooltip: 'Delete skill',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteOfferedSkill(skill),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWantedSkillsList() {
    return StreamBuilder<List<WantedSkill>>(
      stream: _firestoreService.getMyWantedSkills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final skills = snapshot.data ?? [];
        if (skills.isEmpty) {
          return _buildEmptyState(
              'You haven\'t requested any skills yet.', Icons.search_outlined);
        }

        _ensureWantedSkillImages(skills);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            final skill = skills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () => _showWantedSkillDetails(skill),
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.shade50,
                  backgroundImage: skill.imageUrl != null
                      ? NetworkImage(skill.imageUrl!)
                      : null,
                  child: skill.imageUrl == null
                      ? const Icon(Icons.extension, color: Colors.orange)
                      : null,
                ),
                title: Text(skill.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Category: ${skill.category.isEmpty ? 'Uncategorized' : skill.category} • Level: ${skill.level}\n${skill.remarks}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit request',
                      icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                      onPressed: () => _openEditWantedSkill(skill),
                    ),
                    IconButton(
                      tooltip: 'Delete request',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteWantedSkill(skill),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _ensureWantedSkillImages(List<WantedSkill> skills) {
    if (_isHydratingWantedImages) return;

    final missingImageSkills = skills
        .where((s) =>
            (s.imageUrl == null || s.imageUrl!.isEmpty) &&
            !_hydratedWantedSkillIds.contains(s.id))
        .toList();

    if (missingImageSkills.isEmpty) return;

    for (final skill in missingImageSkills) {
      _hydratedWantedSkillIds.add(skill.id);
    }

    _isHydratingWantedImages = true;
    Future<void>(() async {
      try {
        await _firestoreService.hydrateWantedSkillImages(missingImageSkills);
      } finally {
        _isHydratingWantedImages = false;
      }
    });
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _openEditOfferedSkill(OfferedSkill skill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSkillScreen(
          isOffered: true,
          initialOfferedSkill: skill,
        ),
      ),
    );
  }

  Future<void> _openEditWantedSkill(WantedSkill skill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSkillScreen(
          isOffered: false,
          initialWantedSkill: skill,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOfferedSkill(OfferedSkill skill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill'),
        content: Text('Delete "${skill.name}" from your offered skills?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _firestoreService.deleteOfferedSkill(skill.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete skill: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteWantedSkill(WantedSkill skill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill Request'),
        content: Text('Delete "${skill.name}" from your wanted skills?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _firestoreService.deleteWantedSkill(skill.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill request deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete skill request: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openOfferedSkillDetails(OfferedSkill skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit skill',
                    icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                    onPressed: () {
                      Navigator.pop(context);
                      _openEditOfferedSkill(skill);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (skill.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    skill.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(skill.category)),
                  Chip(label: Text(skill.level)),
                ],
              ),
              const SizedBox(height: 12),
              Text(skill.about),
              const SizedBox(height: 12),
              const Text('What they will learn',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skill.learningPoints
                    .map((point) => Chip(label: Text(point)))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openEditOfferedSkill(skill),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkillDetailScreen(
                              skill: Skill.fromOffered(skill),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal),
                      child: const Text('Open Full Page'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWantedSkillDetails(WantedSkill skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(skill.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Edit request',
                    icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                    onPressed: () {
                      Navigator.pop(context);
                      _openEditWantedSkill(skill);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(skill.category.isEmpty
                        ? 'Uncategorized'
                        : skill.category),
                    backgroundColor: Colors.orange.shade50,
                  ),
                  Chip(
                    label: Text(skill.level),
                    backgroundColor: Colors.orange.shade50,
                  ),
                ],
              ),
              if (skill.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    skill.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Remarks',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 6),
              Text(skill.remarks.isEmpty ? 'No remarks added.' : skill.remarks),
              const SizedBox(height: 16),
              const Text('Other Relevant Skills',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 6),
              if (skill.otherRelevantSkills.isEmpty)
                const Text('No additional skills listed.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skill.otherRelevantSkills
                      .map((s) => Chip(
                          label: Text(s), backgroundColor: Colors.teal.shade50))
                      .toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
