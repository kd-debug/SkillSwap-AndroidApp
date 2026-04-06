import 'package:flutter/material.dart';
import '../chat/skill_chat_screen.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/skill_request.dart';

// --- Requests Screen ---
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for new messages and show notifications
    _listenForNewMessages();
  }

  void _listenForNewMessages() {
    _firestoreService.getNewMessagesStream().listen((messages) {
      // Show notification for each new message
      for (final messageData in messages) {
        if (mounted) {
          _showMessageNotification(
            senderName: messageData['senderName'] ?? 'Someone',
            messageText: messageData['messageText'] ?? '',
            skillName: messageData['requestedSkillName'] ?? 'a skill',
            chatId: messageData['chatId'] ?? '',
          );
        }
      }
    });
  }

  void _showMessageNotification({
    required String senderName,
    required String messageText,
    required String skillName,
    required String chatId,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New message from $senderName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              messageText.length > 50
                  ? '${messageText.substring(0, 50)}...'
                  : messageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF005B5B),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View Chat',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to the specific chat
            _openChatFromNotification(chatId);
          },
        ),
      ),
    );
  }

  Future<void> _openChatFromNotification(String chatId) async {
    try {
      // Get the skill request associated with this chat
      final request = await _firestoreService.getSkillRequestById(chatId);
      if (request != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SkillChatScreen(request: request),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text('Skill Requests',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedRequestsList(),
          _buildSentRequestsList(),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestsList() {
    return StreamBuilder<List<SkillRequest>>(
      stream: _firestoreService.getReceivedRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
              'Error loading requests: ${snapshot.error}', Icons.error_outline);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              'No requests received yet', Icons.inbox_outlined);
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return RequestCard(request: request, isReceived: true);
          },
        );
      },
    );
  }

  Widget _buildSentRequestsList() {
    return StreamBuilder<List<SkillRequest>>(
      stream: _firestoreService.getSentRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
              'Error loading requests: ${snapshot.error}', Icons.error_outline);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
              'You haven\'t sent any requests', Icons.send_outlined);
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return RequestCard(request: request, isReceived: false);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Request Card Component ---
class RequestCard extends StatelessWidget {
  final SkillRequest request;
  final bool isReceived;

  const RequestCard(
      {super.key, required this.request, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = request.status == 'pending';
    final isAccepted = request.status == 'accepted';
    final displayOfferedSkills = request.offeredSkillNames
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where(
          (s) =>
              s.toLowerCase() !=
              request.requestedSkillName.trim().toLowerCase(),
        )
        .toSet()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isAccepted
              ? Colors.green.shade200
              : (isPending ? Colors.teal.shade100 : Colors.grey.shade200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.teal.shade50,
                  child: Text(
                    _avatarInitial(
                        isReceived ? request.fromUserName : request.toUserName),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived
                            ? '${request.fromUserName} wants to learn'
                            : 'You requested from ${request.toUserName}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.requestedSkillName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Requested on ${_formatDate(request.timestamp)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            const Divider(height: 24),
            if (isReceived && request.status == 'pending') ...[
              Text(
                'They can teach you in return',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayOfferedSkills
                    .map((skill) => Chip(
                          label:
                              Text(skill, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.teal.shade50,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRequest(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAcceptDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == 'accepted') ...[
              Text(
                request.selectedSkillName == null ||
                        request.selectedSkillName!.trim().isEmpty
                    ? 'Accepted as mentorship only'
                    : (isReceived
                        ? 'You chose to learn: ${request.selectedSkillName}'
                        : 'They chose to learn: ${request.selectedSkillName}'),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
              const SizedBox(height: 10),
              StreamBuilder<String?>(
                stream: FirestoreService().getChatLastMessage(
                    FirestoreService().chatIdForRequest(request.id)),
                builder: (context, snapshot) {
                  final text = snapshot.data;
                  if (text == null || text.trim().isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No messages yet. Start chat to coordinate your swap.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Latest message: $text',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.status == 'pending'
                      ? (isReceived
                          ? 'Waiting for your response'
                          : 'Waiting for their response')
                      : (request.status == 'declined'
                          ? 'This request was declined'
                          : 'Request status: ${request.status}'),
                  style: TextStyle(
                      color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange.shade700;
    if (status == 'accepted') color = Colors.green.shade700;
    if (status == 'declined') color = Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _avatarInitial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  void _declineRequest(BuildContext context) {
    FirestoreService().respondToRequest(request.id, 'declined');
  }

  void _showAcceptDialog(BuildContext context) async {
    final liveOfferedSkills =
        await FirestoreService().getAllOfferedSkills().first;
    if (!context.mounted) return;

    final liveSkillNames = liveOfferedSkills
        .where((s) => s.userId == request.fromUserId)
        .map((s) => s.name.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final filteredSkills = request.offeredSkillNames
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => liveSkillNames.contains(s))
        .where(
          (s) =>
              s.toLowerCase() !=
              request.requestedSkillName.trim().toLowerCase(),
        )
        .toSet()
        .toList();

    if (filteredSkills.isEmpty) {
      filteredSkills.addAll(
        liveSkillNames
            .where((s) =>
                s.toLowerCase() !=
                request.requestedSkillName.trim().toLowerCase())
            .toList(),
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFF9FCFD), Color(0xFFF2F8F8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.handshake_outlined,
                        color: Colors.teal.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Accept Skill Swap',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${request.fromUserName} requested ${request.requestedSkillName}. Pick what you want to learn back.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (filteredSkills.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'No valid return skills available in this request.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              else
                ...filteredSkills.map(
                  (skill) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        FirestoreService().respondToRequest(
                          request.id,
                          'accepted',
                          selectedSkillName: skill,
                        );
                        Navigator.pop(context);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade100),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.school_outlined,
                                    color: Colors.teal.shade700, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.teal.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirestoreService()
                        .respondToRequest(request.id, 'accepted');
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Accept as Mentorship'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: BorderSide(color: Colors.teal.shade200),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillChatScreen(request: request),
      ),
    );
  }
}
