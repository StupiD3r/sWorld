import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';

class CommunityPage extends StatefulWidget {
  final String username;
  final bool isAdmin;
  final String? photoUrl;

  const CommunityPage({
    super.key,
    required this.username,
    this.isAdmin = false,
    this.photoUrl,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Stream subscription for real-time messages
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize chat with welcome message if needed
      await _chatService.initializeChat();
      
      // Load initial messages
      final initialMessages = await _chatService.getRecentMessages();
      setState(() {
        _messages.clear();
        _messages.addAll(initialMessages);
      });
      
      // Listen for real-time updates
      _messageSubscription = _chatService.getMessagesStream().listen(
        (newMessages) {
          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
          });
          _scrollToBottom();
        },
        onError: (error) {
          print('Error in message stream: $error');
        },
      );
      
      _scrollToBottom();
    } catch (e) {
      print('Error initializing chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    
    try {
      setState(() => _isLoading = true);
      _messageController.clear();
      
      // Send message to Firebase
      await _chatService.sendMessage(
        username: widget.username,
        message: messageText,
        isAdmin: widget.isAdmin,
        photoUrl: widget.photoUrl,
      );
      
      // Message will appear automatically through the stream listener
      
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Restore message text if sending failed
      _messageController.text = messageText;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.people_alt, color: Color(0xFF5CE1E6), size: 24),
            const SizedBox(width: 12),
            const Text(
              'Community Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isAdmin) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF5CE1E6)),
                onPressed: _showResetChatDialog,
                tooltip: 'Reset Chat',
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5CE1E6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B4A).withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5CE1E6).withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),
          ),

          // Message input area
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B4A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5CE1E6), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF5CE1E6),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Color(0xFF5CE1E6)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF5CE1E6).withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF5CE1E6),
            backgroundImage: message.photoUrl != null ? NetworkImage(message.photoUrl!) : null,
            child: message.photoUrl == null
                ? Text(
                    message.username.isNotEmpty ? message.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF0A1628),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: message.isAdmin
                            ? Colors.red.withOpacity(0.8)
                            : const Color(0xFF5CE1E6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isAdmin) ...[
                            const Icon(Icons.admin_panel_settings, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            message.username,
                            style: TextStyle(
                              color: message.isAdmin ? Colors.white : const Color(0xFF5CE1E6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Message Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isAdmin
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF5CE1E6).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isAdmin
                          ? Colors.red.withOpacity(0.3)
                          : const Color(0xFF5CE1E6).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isAdmin ? Colors.red.withOpacity(0.9) : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B4A),
        title: const Text(
          'Reset Community Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to reset the entire community chat?\n\nThis will:\n• Delete all messages\n• Clear chat history\n• Add a fresh welcome message\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF5CE1E6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetChat() async {
    try {
      setState(() => _isLoading = true);
      
      await _chatService.resetChat();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community chat has been reset successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
