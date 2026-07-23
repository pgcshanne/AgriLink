import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'package:agrilink/services/free_ai_service.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/app_translations.dart';
import 'package:agrilink/services/openrouter_service.dart';

class AiChatOverlay extends StatefulWidget {
  const AiChatOverlay({super.key});

  @override
  State<AiChatOverlay> createState() => _AiChatOverlayState();
}

class _AiChatOverlayState extends State<AiChatOverlay> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  final List<_ChatMessage> _messages = [];

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
        if (_messages.isEmpty) {
          _messages.add(_ChatMessage(
            text: AppTranslations.getText('agribot_greeting'),
            isUser: false,
          ));
        }
      } else {
        _animController.reverse();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final reply = await FreeAiService.generateResponse(text, history);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Kumusta! I am here to help. Could you please rephrase your farming question?',
            isUser: false,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat Window
        if (_isOpen)
          Positioned(
            bottom: 80,
            right: 16,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: _buildChatWindow(),
            ),
          ),

        // FAB
        Positioned(
          bottom: 12,
          right: 16,
          child: _buildFab(),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggleChat,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimaryGreen, Color(0xFF229658)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isOpen
              ? const Icon(Icons.close, color: Colors.white, size: 26, key: ValueKey('close'))
              : const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 28, key: ValueKey('bot')),
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final chatHeight = (screenHeight * 0.55).clamp(350.0, 520.0);
    final chatWidth = (screenWidth - 32).clamp(280.0, 380.0);

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: chatWidth,
        height: chatHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildChatHeader(),
            // Messages
            Expanded(child: _buildMessagesList()),
            // Input
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGreen, Color(0xFF229658)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AgriBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Online • System Connected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // AI Key Settings
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
            onPressed: _showApiKeyDialog,
            tooltip: 'AI Key Settings',
          ),
          // Clear chat
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.8), size: 20),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: 'Chat cleared! 🌾 How can I help you today?',
                  isUser: false,
                ));
              });
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController();
    UserSession.getOpenRouterKey().then((key) {
      if (key != null && key.isNotEmpty) {
        keyController.text = key;
      } else {
        keyController.text = OpenRouterService.defaultKey;
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('OpenRouter AI Key Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AgriBot uses your OpenRouter API key for high-speed AI completions, connected live to your Bogo City system data.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: 'OpenRouter API Key',
                hintText: 'sk-or-v1-...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Key Active: sk-or-v1-342f1a... (OpenRouter LLM AI)',
              style: TextStyle(fontSize: 11, color: kPrimaryGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = keyController.text.trim();
              await UserSession.saveOpenRouterKey(key);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('OpenRouter AI key updated!'),
                    backgroundColor: kPrimaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kLightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: kPrimaryGreen, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? kPrimaryGreen : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text.replaceAll('*', ''),
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: kPrimaryGreen, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.grey[400]!.withValues(alpha: 0.4 + (value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask about farming...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryGreen, Color(0xFF229658)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
