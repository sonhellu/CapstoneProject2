import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/chat_models.dart';
import 'services/chat_service.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF0F2F5);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6A6A6A);
  static const textLight = Color(0xFFADB5BD);
  static const myBubble = Color(0xFF003478);
  static const partnerBubble = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF5F7FA);
  static const onlineGreen = Color(0xFF4CAF50);
}

// ─────────────────────────── Screen ───────────────────────────
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chat,
  });

  final ChatModel chat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _messages = <MessageModel>[];

  bool _isLoadingInitial = true;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  int _currentPage = 1;
  bool _canSend = false;

  StreamSubscription<MessageModel>? _messageSub;
  late final AnimationController _sendBtnCtrl;

  @override
  void initState() {
    super.initState();
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadInitialMessages();
    _messageSub =
        ChatService.instance.incomingMessages.listen(_onIncomingMessage);
    _inputCtrl.addListener(() {
      final canSend = _inputCtrl.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
        if (canSend) {
          _sendBtnCtrl.forward();
        } else {
          _sendBtnCtrl.reverse();
        }
      }
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _sendBtnCtrl.dispose();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // When scrolled to top → load older messages
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 80 &&
        !_isLoadingOlder &&
        _hasMoreOlder) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    final msgs = await ChatService.instance.getMessages(widget.chat.id);
    if (!mounted) return;
    setState(() {
      _messages.addAll(msgs);
      _isLoadingInitial = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    setState(() => _isLoadingOlder = true);
    final older = await ChatService.instance.getMessages(
      widget.chat.id,
      page: _currentPage + 1,
    );
    if (!mounted) return;
    if (older.isEmpty) {
      setState(() {
        _isLoadingOlder = false;
        _hasMoreOlder = false;
      });
      return;
    }
    final prevExtent = _scrollCtrl.position.maxScrollExtent;
    setState(() {
      _messages.insertAll(0, older);
      _currentPage++;
      _isLoadingOlder = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newExtent = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.jumpTo(_scrollCtrl.offset + (newExtent - prevExtent));
    });
  }

  void _onIncomingMessage(MessageModel msg) {
    if (!mounted) return;
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _canSend = false);
    _sendBtnCtrl.reverse();
    HapticFeedback.lightImpact();

    final msg =
        await ChatService.instance.sendMessage(widget.chat.id, text);
    if (!mounted) return;
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final partner = widget.chat.partner;
    return Scaffold(
      backgroundColor: _T.background,
      appBar: _buildAppBar(partner),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingInitial
                ? _buildSkeleton()
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PartnerModel partner) {
    return AppBar(
      backgroundColor: _T.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: const Color(0x14000000),
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: _T.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              _Avatar(initial: partner.avatarInitial, size: 36, fontSize: 14),
              if (partner.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _T.onlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.textDark,
                ),
              ),
              Text(
                partner.isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: partner.isOnline
                      ? _T.onlineGreen
                      : _T.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: _T.textDark, size: 22),
          onPressed: () => _showOptions(context, partner),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F2F5)),
      ),
    );
  }

  Widget _buildMessageList() {
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        itemCount: _messages.length +
            (_isLoadingOlder ? 1 : 0) +
            (_hasMoreOlder && !_isLoadingOlder ? 1 : 0),
        itemBuilder: (context, index) {
          // Top: load older button or spinner
          if (index == 0 && _isLoadingOlder) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _T.primary,
                  ),
                ),
              ),
            );
          }
          if (index == 0 && _hasMoreOlder) {
            return _LoadOlderButton(onTap: _loadOlderMessages);
          }

          final msgIndex = _isLoadingOlder || _hasMoreOlder
              ? index - 1
              : index;
          final msg = _messages[msgIndex];
          final prev = msgIndex > 0 ? _messages[msgIndex - 1] : null;
          final next = msgIndex < _messages.length - 1
              ? _messages[msgIndex + 1]
              : null;

          final showDateSeparator = prev == null ||
              !_isSameDay(prev.timestamp, msg.timestamp);
          final isGroupStart = prev == null ||
              prev.senderId != msg.senderId ||
              msg.timestamp.difference(prev.timestamp).inMinutes > 5 ||
              showDateSeparator;
          final isGroupEnd = next == null ||
              next.senderId != msg.senderId ||
              next.timestamp.difference(msg.timestamp).inMinutes > 5 ||
              !_isSameDay(msg.timestamp, next.timestamp);

          return Column(
            children: [
              if (showDateSeparator) _DateSeparator(date: msg.timestamp),
              _BubbleTile(
                message: msg,
                partnerInitial: widget.chat.partner.avatarInitial,
                isGroupStart: isGroupStart,
                isGroupEnd: isGroupEnd,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: _T.surface,
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _T.inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: _T.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: _T.textLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _canSend ? _send() : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _sendBtnCtrl,
            builder: (context, _) {
              final v = _sendBtnCtrl.value;
              return Transform.scale(
                scale: 0.85 + 0.15 * v,
                child: GestureDetector(
                  onTap: _canSend ? _send : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _canSend
                          ? _T.primary
                          : const Color(0xFFDDE3EA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _canSend
                          ? Colors.white
                          : _T.textLight,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonBubble(isMe: i.isEven),
    );
  }

  void _showOptions(BuildContext context, PartnerModel partner) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text('View Profile',
                  style: GoogleFonts.notoSansKr(fontSize: 14)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded,
                  color: Colors.red),
              title: Text('Block User',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────── Load Older Button ───────────────────────────
class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_arrow_up_rounded,
                    size: 16, color: _T.textGrey),
                const SizedBox(width: 4),
                Text(
                  'Load older messages',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: _T.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Date Separator ───────────────────────────
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFFE0E4EA), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: _T.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: Color(0xFFE0E4EA), thickness: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────── Bubble Tile ───────────────────────────
class _BubbleTile extends StatelessWidget {
  const _BubbleTile({
    required this.message,
    required this.partnerInitial,
    required this.isGroupStart,
    required this.isGroupEnd,
  });

  final MessageModel message;
  final String partnerInitial;
  final bool isGroupStart;
  final bool isGroupEnd;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.only(
        top: isGroupStart ? 6 : 2,
        bottom: isGroupEnd ? 2 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Partner avatar (left side, only for last in group)
          if (!isMe) ...[
            if (isGroupEnd)
              _Avatar(initial: partnerInitial, size: 28, fontSize: 11)
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],

          // Bubble column
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _Bubble(
                  message: message,
                  isMe: isMe,
                  isGroupStart: isGroupStart,
                  isGroupEnd: isGroupEnd,
                ),
                if (isGroupEnd)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 10,
                        color: _T.textLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Spacer on right for partner messages
          if (!isMe) const SizedBox(width: 40),
          // Spacer on left for my messages
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final hour = (h % 12 == 0 ? 12 : h % 12).toString();
    return '$hour:$m $period';
  }
}

// ─────────────────────────── Bubble ───────────────────────────
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.isGroupStart,
    required this.isGroupEnd,
  });

  final MessageModel message;
  final bool isMe;
  final bool isGroupStart;
  final bool isGroupEnd;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const rSmall = Radius.circular(4);

    final borderRadius = isMe
        ? BorderRadius.only(
            topLeft: r,
            topRight: isGroupStart ? r : rSmall,
            bottomLeft: r,
            bottomRight: isGroupEnd ? rSmall : rSmall,
          )
        : BorderRadius.only(
            topLeft: isGroupStart ? r : rSmall,
            topRight: r,
            bottomLeft: isGroupEnd ? rSmall : rSmall,
            bottomRight: r,
          );

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message copied',
              style: GoogleFonts.notoSansKr(fontSize: 13),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _T.myBubble : _T.partnerBubble,
          borderRadius: borderRadius,
          boxShadow: isMe
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          message.content,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: isMe ? Colors.white : _T.textDark,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Skeleton Bubble ───────────────────────────
class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({required this.isMe});
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _circle(28),
            const SizedBox(width: 6),
          ],
          _rect(isMe ? 180 : 200, 40),
          if (isMe) const SizedBox(width: 40),
          if (!isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _circle(double s) => Container(
        width: s,
        height: s,
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
      );

  Widget _rect(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

// ─────────────────────────── Avatar ───────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    this.size = 36,
    this.fontSize = 14,
  });
  final String initial;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _T.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
