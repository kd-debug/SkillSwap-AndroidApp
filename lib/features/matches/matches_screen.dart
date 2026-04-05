import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/skill_model.dart';
import '../../core/models/skill_request.dart';
import '../../core/models/user_profile.dart';
import '../../main.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  UserProfile? _profile;
  List<OfferedSkill> _nearbyAndFit = [];
  List<_CourseSuggestion> _courseSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final profile = await _firestoreService.getUserProfile();
    final myOffered = await _firestoreService.getMyOfferedSkills().first;
    final myWanted = await _firestoreService.getMyWantedSkills().first;
    final allOffered = await _firestoreService.getAllOfferedSkills().first;
    final sentRequests = await _firestoreService.getSentRequests().first;
    final receivedRequests =
        await _firestoreService.getReceivedRequests().first;

    final acceptedRequestedSkillIds = sentRequests
        .where((r) => r.status == 'accepted')
        .map((r) => r.requestedSkillId)
        .toSet();
    final acceptedSelectedPairs = receivedRequests
        .where((r) =>
            r.status == 'accepted' &&
            r.selectedSkillName != null &&
            r.selectedSkillName!.trim().isNotEmpty)
        .map((r) =>
            '${r.fromUserId}|${r.selectedSkillName!.trim().toLowerCase()}')
        .toSet();

    final myOfferedNames = myOffered.map((s) => s.name.toLowerCase()).toSet();
    final myWantedNames = myWanted
        .expand((s) => [s.name.toLowerCase(), s.category.toLowerCase()])
        .toSet();
    final myCategories = myOffered.map((s) => s.category.toLowerCase()).toSet();

    final candidateSuggestions = <OfferedSkill>[];
    for (final skill in allOffered) {
      if (skill.userId == FirebaseAuth.instance.currentUser?.uid) continue;
      if (acceptedRequestedSkillIds.contains(skill.id)) continue;
      if (acceptedSelectedPairs
          .contains('${skill.userId}|${skill.name.trim().toLowerCase()}')) {
        continue;
      }
      final matchesWanted = myWantedNames.contains(skill.name.toLowerCase()) ||
          myWantedNames.contains(skill.category.toLowerCase());
      if (matchesWanted) {
        candidateSuggestions.add(skill);
      }
    }

    candidateSuggestions.sort((a, b) {
      final aScore = _scoreRecommendation(a, myWantedNames, myCategories);
      final bScore = _scoreRecommendation(b, myWantedNames, myCategories);
      return bScore.compareTo(aScore);
    });

    final courses = _buildPersonalizedCourses(
      myOffered: myOffered,
      myWanted: myWanted,
      sentRequests: sentRequests,
      receivedRequests: receivedRequests,
      myCategories: myCategories,
      myOfferedNames: myOfferedNames,
    );

    if (mounted) {
      setState(() {
        _profile = profile;
        _nearbyAndFit = candidateSuggestions;
        _courseSuggestions = courses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F7),
      appBar: AppBar(
        title: const Text('Smart Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMatches),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _sectionTitle('Skill Fit'),
                const SizedBox(height: 10),
                if (_nearbyAndFit.isEmpty)
                  _emptyHint(
                    'No strong nearby swaps yet. Add more wanted skills or allow location for better results.',
                  )
                else
                  ..._nearbyAndFit
                      .take(8)
                      .map((skill) => _buildSkillRecommendationCard(
                            skill: skill,
                            reason: _reasonForSkill(skill),
                            accent: Colors.teal,
                          )),
                const SizedBox(height: 16),
                _sectionTitle('Free Courses to Complete Gaps'),
                const SizedBox(height: 4),
                Text(
                  'Courses are personalized from your offered skills, wanted skills, and accepted exchanges.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                if (_courseSuggestions.isEmpty)
                  _emptyHint(
                    'Add at least one wanted skill to get personalized free-course recommendations.',
                  )
                else
                  ..._courseSuggestions
                      .map((course) => _buildCourseCard(course)),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'there';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF005B5B), Color(0xFF149D9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, $name',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'This feed combines Nearby + Skill Fit, profile-completion goals, and high-quality free learning resources so your progress never blocks.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('Accepted-swap aware', Icons.task_alt_outlined),
              _badge('Free structured courses', Icons.school_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _emptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
    );
  }

  Widget _buildSkillRecommendationCard({
    required OfferedSkill skill,
    required String reason,
    required Color accent,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: accent.withValues(alpha: 0.12),
          backgroundImage:
              skill.imageUrl != null ? NetworkImage(skill.imageUrl!) : null,
          child: skill.imageUrl == null
              ? Text(skill.name.isNotEmpty ? skill.name[0] : '?',
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(skill.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${skill.userName} · ${skill.category} · ${skill.level}'),
              const SizedBox(height: 6),
              Text(reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill('Match confidence ${_matchConfidence(skill)}%',
                      Colors.teal.shade100),
                  _pill(
                      'Expected impact: profile growth', Colors.green.shade100),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _openSkill(skill),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCourseCard(_CourseSuggestion course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child:
                      Icon(Icons.school_outlined, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(course.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () => _openCourse(course.url),
                  child: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${course.provider} · ${course.level} · ${course.duration}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(course.reason),
            const SizedBox(height: 10),
            const Text('What you will cover',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...course.covers.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCourseInfo(course),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCourse(course.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Start Learning'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSkill(OfferedSkill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SkillDetailScreen(skill: Skill.fromOffered(skill)),
      ),
    );
  }

  void _showCourseInfo(_CourseSuggestion course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(course.provider,
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('${course.level} · ${course.duration}',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Text(course.reason),
                const SizedBox(height: 16),
                const Text('Covered in this resource',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...course.covers.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCourse(course.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Free Resource'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCourse(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  int _scoreRecommendation(
    OfferedSkill skill,
    Set<String> wantedNames,
    Set<String> myCategories,
  ) {
    var score = 0;
    if (wantedNames.contains(skill.name.toLowerCase()) ||
        wantedNames.contains(skill.category.toLowerCase())) {
      score += 100;
    }
    if (myCategories.contains(skill.category.toLowerCase())) score += 15;
    if (skill.level.toLowerCase() == 'beginner') score += 5;
    return score;
  }

  int _matchConfidence(OfferedSkill skill) {
    final categories =
        _profile?.interests.map((e) => e.toLowerCase()).toSet() ?? <String>{};
    var score = 55;
    if (categories.contains(skill.category.toLowerCase())) score += 20;
    if (skill.level.toLowerCase() == 'beginner') score += 5;
    return score.clamp(40, 98);
  }

  List<_CourseSuggestion> _buildPersonalizedCourses({
    required List<OfferedSkill> myOffered,
    required List<WantedSkill> myWanted,
    required List<SkillRequest> sentRequests,
    required List<SkillRequest> receivedRequests,
    required Set<String> myCategories,
    required Set<String> myOfferedNames,
  }) {
    final suggestions = <_CourseSuggestion>[];
    final seenTitles = <String>{};
    final catalog = _courseCatalog();

    _CourseSuggestion? bestForTerms(List<String> terms, {String? preferred}) {
      final normalizedTerms = terms
          .map((t) => t.toLowerCase())
          .expand((t) => t.split(RegExp(r'[^a-z0-9]+')))
          .where((t) => t.isNotEmpty)
          .toSet();

      int bestScore = -1;
      _CourseTemplate? best;
      for (final template in catalog) {
        var score = 0;
        for (final tag in template.tags) {
          if (normalizedTerms.contains(tag)) score += 4;
          if (normalizedTerms.any((t) => t.contains(tag) || tag.contains(t))) {
            score += 1;
          }
        }
        if (preferred != null && template.tags.contains(preferred)) {
          score += 3;
        }
        if (score > bestScore) {
          bestScore = score;
          best = template;
        }
      }

      if (best == null || bestScore <= 0) return null;
      return best!.toCourse();
    }

    void addSuggestion(_CourseSuggestion suggestion, String reason) {
      if (seenTitles.contains(suggestion.title)) return;
      seenTitles.add(suggestion.title);
      suggestions.add(
        _CourseSuggestion(
          title: suggestion.title,
          provider: suggestion.provider,
          level: suggestion.level,
          duration: suggestion.duration,
          url: suggestion.url,
          reason: reason,
          covers: suggestion.covers,
        ),
      );
    }

    for (final wanted in myWanted) {
      final supportingSkill = myOffered.firstWhere(
        (s) => s.category.toLowerCase() == wanted.category.toLowerCase(),
        orElse: () => myOffered.isNotEmpty
            ? myOffered.first
            : OfferedSkill(
                id: '',
                userId: '',
                userName: '',
                name: '',
                category: '',
                level: '',
                about: '',
                learningPoints: const [],
              ),
      );

      final hasSameCategorySupport = supportingSkill.name.isNotEmpty &&
          supportingSkill.category.toLowerCase() ==
              wanted.category.toLowerCase();

      final candidate = bestForTerms(
        [
          wanted.name,
          wanted.category,
          wanted.remarks,
          if (supportingSkill.name.isNotEmpty) supportingSkill.name,
        ],
        preferred: wanted.category.toLowerCase(),
      );

      if (candidate != null) {
        final reason = hasSameCategorySupport
            ? 'You offer ${supportingSkill.name} and want ${wanted.name}. This course bridges your current strength to your target skill.'
            : 'You want ${wanted.name} in ${wanted.category}. This course builds a clean foundation for that path.';
        addSuggestion(candidate, reason);
      }

      if (!hasSameCategorySupport && myOffered.isNotEmpty) {
        final categoryBridge = bestForTerms(
          [wanted.category, wanted.name, myOffered.first.category],
          preferred: wanted.category.toLowerCase(),
        );
        if (categoryBridge != null) {
          addSuggestion(
            categoryBridge,
            'You currently offer ${myOffered.first.category} but want ${wanted.category}. This recommendation helps you shift categories smoothly.',
          );
        }
      }
    }

    final acceptedLearningSkills = <String>{
      ...sentRequests
          .where((r) => r.status == 'accepted')
          .map((r) => r.requestedSkillName.trim())
          .where((n) => n.isNotEmpty),
      ...receivedRequests
          .where((r) =>
              r.status == 'accepted' &&
              r.selectedSkillName != null &&
              r.selectedSkillName!.trim().isNotEmpty)
          .map((r) => r.selectedSkillName!.trim()),
    };

    for (final acceptedSkill in acceptedLearningSkills) {
      final reinforcement = bestForTerms(
        [acceptedSkill, ...myCategories, ...myOfferedNames],
      );
      if (reinforcement != null) {
        addSuggestion(
          reinforcement,
          'You already accepted a swap for $acceptedSkill. Use this resource to accelerate what you are currently learning.',
        );
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add(_CourseSuggestion(
        title: 'Open University Free Learning Path',
        provider: 'Curated fallback',
        level: 'Beginner',
        duration: 'Self-paced',
        url: 'https://www.open.edu/openlearn/',
        reason:
            'No exact match was found yet. This path still gives you structured and free progression.',
        covers: const [
          'Structured beginner learning plans',
          'Topic-based progression with free resources',
          'Skills to improve profile completeness',
        ],
      ));
    }

    return suggestions.take(6).toList();
  }

  List<_CourseTemplate> _courseCatalog() {
    return const [
      _CourseTemplate(
        title: 'Java JDBC Full Tutorial',
        provider: 'Telusko (YouTube)',
        level: 'Beginner to Intermediate',
        duration: '2h+',
        url: 'https://www.youtube.com/watch?v=3OrEsC-QjUA',
        covers: [
          'Connecting Java applications to SQL databases',
          'Prepared statements and result handling',
          'CRUD flow with robust JDBC patterns',
        ],
        tags: ['java', 'jdbc', 'database', 'sql', 'programming'],
      ),
      _CourseTemplate(
        title: 'Spring Boot REST API Crash Course',
        provider: 'freeCodeCamp (YouTube)',
        level: 'Intermediate',
        duration: '2h 20m',
        url: 'https://www.youtube.com/watch?v=vtPkZShrvXQ',
        covers: [
          'REST API design with Spring Boot',
          'Controller/service/repository layering',
          'Validation and database integration',
        ],
        tags: ['java', 'api', 'rest', 'backend', 'programming'],
      ),
      _CourseTemplate(
        title: 'Flutter State Management Full Course',
        provider: 'freeCodeCamp (YouTube)',
        level: 'Beginner to Intermediate',
        duration: '3h 30m',
        url: 'https://www.youtube.com/watch?v=3tm-R7ymwhc',
        covers: [
          'Provider and state flow fundamentals',
          'Architecture patterns for maintainable Flutter apps',
          'Practical state management implementation walkthrough',
        ],
        tags: ['flutter', 'dart', 'state', 'programming', 'mobile'],
      ),
      _CourseTemplate(
        title: 'MDN: Fetching Data from APIs',
        provider: 'MDN Web Docs',
        level: 'Beginner',
        duration: 'Self-paced (~1h)',
        url:
            'https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Client-side_web_APIs/Fetching_data',
        covers: [
          'How HTTP requests work',
          'Fetch API and JSON parsing',
          'Error handling and response validation',
        ],
        tags: ['api', 'http', 'rest', 'web', 'programming'],
      ),
      _CourseTemplate(
        title: 'Figma Design System Basics',
        provider: 'Figma Learn',
        level: 'Beginner',
        duration: 'Self-paced (~1.5h)',
        url:
            'https://help.figma.com/hc/en-us/articles/360040314193-Guide-to-components-in-Figma',
        covers: [
          'Components and variants',
          'Reusable design tokens',
          'Maintaining UI consistency',
        ],
        tags: ['figma', 'design', 'ui', 'ux', 'branding'],
      ),
      _CourseTemplate(
        title: 'BBC Learning English: Speaking Practice',
        provider: 'BBC Learning English',
        level: 'Beginner',
        duration: 'Self-paced',
        url:
            'https://www.bbc.co.uk/learningenglish/english/features/everyday-english',
        covers: [
          'Everyday conversation patterns',
          'Fluency-focused speaking prompts',
          'Pronunciation and confidence drills',
        ],
        tags: ['english', 'language', 'speaking', 'conversation', 'spoken'],
      ),
      _CourseTemplate(
        title: 'Ear Training Exercises',
        provider: 'musictheory.net',
        level: 'Beginner',
        duration: '10-20 min sessions',
        url: 'https://www.musictheory.net/exercises',
        covers: [
          'Interval recognition',
          'Chord and scale listening practice',
          'Pitch accuracy and music memory',
        ],
        tags: ['music', 'flute', 'instrument', 'ear', 'theory'],
      ),
      _CourseTemplate(
        title: 'Healthy Eating & Meal Planning',
        provider: 'NHS',
        level: 'Beginner',
        duration: 'Self-paced',
        url:
            'https://www.nhs.uk/live-well/eat-well/how-to-eat-a-balanced-diet/eating-a-balanced-diet/',
        covers: [
          'Balanced meal structure',
          'Nutritional basics for planning',
          'Sustainable weekly planning habits',
        ],
        tags: ['culinary', 'nutrition', 'meal', 'cooking', 'food'],
      ),
      _CourseTemplate(
        title: 'Daily Mobility Routine Guide',
        provider: 'Nuffield Health',
        level: 'Beginner',
        duration: '15-20 min sessions',
        url: 'https://www.nuffieldhealth.com/article/mobility-exercises',
        covers: [
          'Joint mobility fundamentals',
          'Beginner-safe movement sequence',
          'Injury prevention and flexibility',
        ],
        tags: ['fitness', 'mobility', 'exercise', 'health'],
      ),
    ];
  }

  String _reasonForSkill(OfferedSkill skill) {
    return 'Skill-fit match: it aligns with your current learning goals or profile gaps.';
  }
}

class _CourseSuggestion {
  final String title;
  final String provider;
  final String level;
  final String duration;
  final String url;
  final String reason;
  final List<String> covers;

  _CourseSuggestion({
    required this.title,
    required this.provider,
    required this.level,
    required this.duration,
    required this.url,
    required this.reason,
    required this.covers,
  });
}

class _CourseTemplate {
  final String title;
  final String provider;
  final String level;
  final String duration;
  final String url;
  final List<String> covers;
  final List<String> tags;

  const _CourseTemplate({
    required this.title,
    required this.provider,
    required this.level,
    required this.duration,
    required this.url,
    required this.covers,
    required this.tags,
  });

  _CourseSuggestion toCourse() {
    return _CourseSuggestion(
      title: title,
      provider: provider,
      level: level,
      duration: duration,
      url: url,
      reason: '',
      covers: covers,
    );
  }
}
