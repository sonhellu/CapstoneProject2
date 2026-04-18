import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/feedback/app_snackbar.dart';
import '../../core/locale/app_locale_resolver.dart';
import '../../core/services/translation_service.dart';
import '../maps/map_focus_controller.dart';
import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import '../maps/services/mock_pin_service.dart';
import 'models/chat_models.dart';
import 'services/chat_service.dart';

const Color _kOnlineGreen = Color(0xFF4CAF50);

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

  /// Cached UID — read once in initState to avoid repeated Firebase calls per render.
  late final String _cachedMyUid;

  /// Tracks all IDs already present in [_messages] to prevent duplicates.
  final _addedIds = <String>{};

  /// Maps temp pending IDs → index in [_messages].
  /// When Firestore confirms a message we replace the pending entry in-place.
  final _pendingMsgIds = <String>{};

  /// Cursor for loading older pages — last doc of the previous descending query.
  DocumentSnapshot<Map<String, dynamic>>? _oldestCursor;

  bool _isLoadingInitial = true;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  bool _canSend = false;

  StreamSubscription<MessageModel>? _messageSub;
  late final AnimationController _sendBtnCtrl;

  @override
  void initState() {
    super.initState();
    _cachedMyUid = FirebaseAuth.instance.currentUser?.uid ?? 'me';
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadInitialMessages();
    _messageSub = ChatService.instance
        .incomingMessagesStream(widget.chat.id)
        .listen(
          _onIncomingMessage,
          // Silently absorb stream errors (e.g. Firestore permission-denied
          // while the app is in the background or the session expires).
          // sendMessage already shows its own error snackbar on failure.
          onError: (_) {},
        );
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
    // Trigger load-older when user scrolls near the TOP of the list
    // (pixels ≈ 0 = top; maxScrollExtent = bottom).
    if (_scrollCtrl.position.pixels <= 80 &&
        !_isLoadingOlder &&
        _hasMoreOlder) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    final (msgs, cursor) = await ChatService.instance
        .getMessages(widget.chat.id, since: widget.chat.lastClearedAt);
    // Reset unread badge when opening chat.
    ChatService.instance.resetUnreadCount(widget.chat.id);
    if (!mounted) return;
    setState(() {
      _oldestCursor = cursor;
      _hasMoreOlder = msgs.length >= ChatService.kPageSize;
      for (final m in msgs) {
        if (_addedIds.add(m.id)) _messages.add(m);
      }
      _isLoadingInitial = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    setState(() => _isLoadingOlder = true);

    final (older, cursor) = await ChatService.instance.getMessages(
      widget.chat.id,
      before: _oldestCursor,
      since: widget.chat.lastClearedAt,
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
      final newOlder = older.where((m) => _addedIds.add(m.id)).toList();
      _messages.insertAll(0, newOlder);
      _oldestCursor = cursor;
      _hasMoreOlder = older.length >= ChatService.kPageSize;
      _isLoadingOlder = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newExtent = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.jumpTo(_scrollCtrl.offset + (newExtent - prevExtent));
    });
  }

  void _onIncomingMessage(MessageModel msg) {
    if (!mounted) return;

    // Check if this Firestore message corresponds to a pending optimistic one.
    // We match by content + senderId because the temp ID differs from Firestore ID.
    final pendingIdx = _pendingMsgIds.isNotEmpty
        ? _messages.indexWhere((m) =>
            m.isPending &&
            m.senderId == msg.senderId &&
            m.content == msg.content)
        : -1;

    if (pendingIdx != -1) {
      // Replace the pending bubble in-place with the confirmed message.
      final tempId = _messages[pendingIdx].id;
      _pendingMsgIds.remove(tempId);
      _addedIds.remove(tempId);
      _addedIds.add(msg.id);
      setState(() => _messages[pendingIdx] = msg);
      return;
    }

    // Regular incoming message — skip if already shown.
    if (!_addedIds.add(msg.id)) return;
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

  // ── Location sharing ──────────────────────────────────────────────────────

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(onShareLocation: _showLocationPicker),
    );
  }

  Future<void> _showLocationPicker() async {
    if (mounted) Navigator.pop(context);
    final locations = MockPinService.instance.allPins.map((pin) => LocationData(
          name: pin.name,
          lat: pin.latLng.latitude,
          lng: pin.latLng.longitude,
          address: pin.notes,
          typeEmoji: pin.type.emoji,
        )).toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<LocationData>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(locations: locations),
    );
    if (picked == null || !mounted) return;
    await _sendLocation(picked);
  }

  Future<void> _sendLocation(LocationData location) async {
    HapticFeedback.lightImpact();
    final tempId =
        'pending_loc_${DateTime.now().microsecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      senderId: _cachedMyUid,
      content: '${location.typeEmoji} ${location.name}',
      timestamp: DateTime.now(),
      type: MessageType.location,
      locationData: location,
      isPending: true,
    );
    _pendingMsgIds.add(tempId);
    _addedIds.add(tempId);
    setState(() => _messages.add(tempMsg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final confirmed = await ChatService.instance.sendLocationMessage(
        widget.chat.id,
        location,
        partnerId: widget.chat.partner.id,
      );
      if (!mounted) return;
      _pendingMsgIds.remove(tempId);
      _addedIds
        ..remove(tempId)
        ..add(confirmed.id);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) _messages[idx] = confirmed;
      });
    } catch (_) {
      if (!mounted) return;
      _pendingMsgIds.remove(tempId);
      _addedIds.remove(tempId);
      setState(() => _messages.removeWhere((m) => m.id == tempId));
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _canSend = false);
    _sendBtnCtrl.reverse();
    HapticFeedback.lightImpact();

    // ── Optimistic insert ────────────────────────────────────────────────────
    final tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      senderId: _cachedMyUid,
      content: text,
      timestamp: DateTime.now(),
      isPending: true,
    );
    _pendingMsgIds.add(tempId);
    _addedIds.add(tempId);
    setState(() => _messages.add(tempMsg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // ── Firestore write ──────────────────────────────────────────────────────
    try {
      final confirmed = await ChatService.instance.sendMessage(
        widget.chat.id,
        text,
        partnerId: widget.chat.partner.id,
      );
      if (!mounted) return;
      // Replace pending bubble with confirmed message in-place.
      _pendingMsgIds.remove(tempId);
      _addedIds
        ..remove(tempId)
        ..add(confirmed.id);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) _messages[idx] = confirmed;
      });
    } catch (_) {
      if (!mounted) return;
      // Remove the pending bubble on failure.
      _pendingMsgIds.remove(tempId);
      _addedIds.remove(tempId);
      setState(() => _messages.removeWhere((m) => m.id == tempId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send — please try again.',
            style: GoogleFonts.notoSansKr(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Opens the modern BottomSheet action menu (replaces PopupMenuButton).
  void _showChatActions(PartnerModel partner) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChatActionsSheet(
        partner: partner,
        onViewProfile: () {
          Navigator.pop(context);
          // TODO: navigate to partner profile screen
        },
        onReport: () {
          Navigator.pop(context);
          // TODO: open report flow
        },
        onDisconnect: () {
          Navigator.pop(context);
          _confirmSoftUnmatch();
        },
      ),
    );
  }

  Future<void> _confirmSoftUnmatch() async {
    final l = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.chatSoftUnmatchConfirmTitle),
        content: Text(l.chatSoftUnmatchConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.chatSoftUnmatchMenu,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    try {
      await ChatService.instance.disconnectPartner(widget.chat.id);
      if (!mounted) return;
      showSuccessSnackBar(context, l.chatDisconnectSuccess);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = widget.chat.partner;
    return Scaffold(
      backgroundColor: context.bg,
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
    final onS = context.onSurface;
    final ring = Theme.of(context).colorScheme.surface;
    return AppBar(
      backgroundColor: context.cardFill,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: const Color(0x14000000),
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: onS),
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
                      color: _kOnlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: ring, width: 2),
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
                  color: onS,
                ),
              ),
              Text(
                partner.isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: partner.isOnline
                      ? _kOnlineGreen
                      : context.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: onS, size: 22),
          onPressed: () => _showChatActions(partner),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Theme.of(context).dividerColor),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primary,
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
                partnerLangTag: widget.chat.partner.nativeLanguage,
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
    final p = context.primary;
    final cs = Theme.of(context).colorScheme;
    final canSendNow = _canSend;
    return Container(
      color: context.cardFill,
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: context.onSurfaceVar, size: 26),
                onPressed: _showAttachSheet,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: context.subtleFill,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: context.outline.withValues(alpha: 0.35)),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: context.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: context.hintColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => canSendNow ? _send() : null,
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
                    onTap: canSendNow ? _send : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: canSendNow
                            ? p
                            : context.outline.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: canSendNow ? cs.onPrimary : context.hintColor,
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
              color: context.cardFill,
              borderRadius: BorderRadius.circular(20),
              boxShadow: context.cardElevationShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: 16, color: context.onSurfaceVar),
                const SizedBox(width: 4),
                Text(
                  'Load older messages',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: context.onSurfaceVar,
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
          Expanded(
              child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: context.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
              child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
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
    required this.partnerLangTag,
    required this.isGroupStart,
    required this.isGroupEnd,
  });

  final MessageModel message;
  final String partnerInitial;
  final String partnerLangTag;
  final bool isGroupStart;
  final bool isGroupEnd;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    if (message.type == MessageType.system) {
      return Padding(
        padding: EdgeInsets.only(
          top: isGroupStart ? 6 : 2,
          bottom: isGroupEnd ? 2 : 0,
        ),
        child: _SystemNotice(text: message.content),
      );
    }

    return AnimatedOpacity(
      opacity: message.isPending ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
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
                if (message.type == MessageType.location &&
                    message.locationData != null)
                  _LocationBubble(
                    location: message.locationData!,
                    isMe: isMe,
                  )
                else
                  _Bubble(
                    message: message,
                    isMe: isMe,
                    isGroupStart: isGroupStart,
                    isGroupEnd: isGroupEnd,
                    partnerLangTag: isMe ? null : partnerLangTag,
                  ),
                if (isGroupEnd)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 10,
                        color: context.hintColor,
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
      ), // Padding
    ); // AnimatedOpacity
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final hour = (h % 12 == 0 ? 12 : h % 12).toString();
    return '$hour:$m $period';
  }
}

// ─────────────────────────── System notice (welcome, etc.) ───────────────────────────
class _SystemNotice extends StatelessWidget {
  const _SystemNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.subtleFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            color: context.onSurfaceVar,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Bubble ───────────────────────────

enum _TxState { idle, loading, done }

class _Bubble extends StatefulWidget {
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.isGroupStart,
    required this.isGroupEnd,
    this.partnerLangTag,
  });

  final MessageModel message;
  final bool isMe;
  final bool isGroupStart;
  final bool isGroupEnd;
  /// Native language tag of the partner (e.g. "KR", "ko"). Null for own messages.
  final String? partnerLangTag;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  _TxState _txState = _TxState.idle;
  String? _translated;

  bool _canTranslate(BuildContext context) {
    if (widget.isMe) return false;
    if (widget.message.type != MessageType.text) return false;
    if (widget.message.content.trim().isEmpty) return false;
    final toIso = AppLocaleResolver.targetLang(context);
    return LangCode.isPapagoSupported(toIso);
  }

  Future<void> _onTranslateTap() async {
    if (_txState == _TxState.loading) return;

    if (_txState == _TxState.done) {
      setState(() => _txState = _TxState.idle);
      return;
    }

    if (_translated != null) {
      setState(() => _txState = _TxState.done);
      return;
    }

    setState(() => _txState = _TxState.loading);

    final toIso = AppLocaleResolver.targetLang(context);

    // 1. Detect actual language of this message (handles mixed-language text).
    // 2. Fallback to partner's profile language if detection fails.
    final detected = await TranslationService.instance
        .detectLanguage(widget.message.content);
    final fromIso = detected ?? LangCode.fromTag(widget.partnerLangTag ?? '');

    // No-op if detected language already matches app language.
    if (fromIso == toIso) {
      if (!mounted) return;
      setState(() {
        _translated = widget.message.content;
        _txState = _TxState.done;
      });
      return;
    }

    final result = await TranslationService.instance.translateText(
      widget.message.content,
      from: fromIso,
      to: toIso,
    );

    if (!mounted) return;
    setState(() {
      _translated = result;
      _txState = _TxState.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final myBg = cs.primary;
    // Partner bubble: in dark mode use cs.surface (distinct from AppBar/cardFill)
    // In light mode use cardFill (white).
    final partnerBg = isDark ? cs.surface : context.cardFill;
    const r = Radius.circular(18);
    const rSmall = Radius.circular(4);
    final isMe = widget.isMe;

    final borderRadius = isMe
        ? BorderRadius.only(
            topLeft: r,
            topRight: widget.isGroupStart ? r : rSmall,
            bottomLeft: r,
            bottomRight: widget.isGroupEnd ? rSmall : rSmall,
          )
        : BorderRadius.only(
            topLeft: widget.isGroupStart ? r : rSmall,
            topRight: r,
            bottomLeft: widget.isGroupEnd ? rSmall : rSmall,
            bottomRight: r,
          );

    final displayText = _txState == _TxState.done
        ? (_translated ?? widget.message.content)
        : widget.message.content;

    final canTx = _canTranslate(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Message bubble ──
        GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Clipboard.setData(ClipboardData(text: widget.message.content));
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? myBg : partnerBg,
              borderRadius: borderRadius,
              border: (!isMe && isDark)
                  ? Border.all(
                      color: cs.outline.withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
              boxShadow: isMe ? null : context.cardElevationShadow,
            ),
            child: Text(
              displayText,
              // notoSans (not notoSansKr) — the base multilingual variant covers
              // Vietnamese combining diacritics; the KR subset does not, causing
              // broken line-wrapping on Vietnamese text.
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isMe ? cs.onPrimary : context.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ),

        // ── Translate chip (partner messages only) ──
        if (canTx) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _onTranslateTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _txState == _TxState.done
                    ? cs.surfaceContainerHighest
                    : cs.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _txState == _TxState.done
                      ? cs.outline.withValues(alpha: 0.45)
                      : cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_txState == _TxState.loading)
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.translate_rounded,
                      size: 11,
                      color: _txState == _TxState.done
                          ? cs.onSurfaceVariant
                          : cs.primary,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    _txState == _TxState.loading
                        ? l.postTranslating
                        : _txState == _TxState.done
                            ? l.postShowOriginal
                            : l.postTranslate,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _txState == _TxState.done
                          ? cs.onSurfaceVariant
                          : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
            _circle(context, 28),
            const SizedBox(width: 6),
          ],
          _rect(context, isMe ? 180 : 200, 40),
          if (isMe) const SizedBox(width: 40),
          if (!isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _circle(BuildContext context, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      );

  Widget _rect(BuildContext context, double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────── Location Bubble ───────────────────────────
class _LocationBubble extends StatelessWidget {
  const _LocationBubble({required this.location, required this.isMe});
  final LocationData location;
  final bool isMe;

  void _openInApp(BuildContext context) {
    MapFocusController.instance.focus(location);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.primary;
    final bg = isMe ? cs.primary : context.cardFill;
    final text = isMe ? cs.onPrimary : context.onSurface;
    final sub = isMe ? cs.onPrimary.withValues(alpha: 0.75) : context.onSurfaceVar;

    return GestureDetector(
      onTap: () => _openInApp(context),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isMe ? null : context.cardElevationShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                color: isMe
                    ? cs.primary.withValues(alpha: 0.75)
                    : context.subtleFill,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(location.typeEmoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    '${location.lat.toStringAsFixed(4)}, '
                    '${location.lng.toStringAsFixed(4)}',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 10, color: sub),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (location.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(location.address,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 11, color: sub, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isMe
                          ? cs.onPrimary.withValues(alpha: 0.15)
                          : p.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded,
                            size: 12,
                            color: isMe ? cs.onPrimary : p),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.chatOpenInMap,
                            style: GoogleFonts.notoSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isMe ? cs.onPrimary : p)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Attach Sheet ───────────────────────────
class _AttachSheet extends StatelessWidget {
  const _AttachSheet({required this.onShareLocation});
  final VoidCallback onShareLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onShareLocation,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Colors.green, size: 26),
                ),
                const SizedBox(height: 6),
                Text('Location',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: context.onSurfaceVar)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Location Picker Sheet ───────────────────────────
class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet({required this.locations});
  final List<LocationData> locations;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = context.primary;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // No fixed padding here — handled inside the scrollable area.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // ── Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: p, size: 20),
                const SizedBox(width: 8),
                Text(
                  l.chatShareLocation,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // ── Scrollable location list ──
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: bottomPad + 8),
              children: locations.map((loc) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(loc.typeEmoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(
                      loc.name,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.onSurface,
                      ),
                    ),
                    subtitle: loc.address.isNotEmpty
                        ? Text(
                            loc.address,
                            style: GoogleFonts.notoSans(
                                fontSize: 12, color: context.onSurfaceVar),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, loc),
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Chat Actions Sheet ───────────────────────────

class _ChatActionsSheet extends StatelessWidget {
  const _ChatActionsSheet({
    required this.partner,
    required this.onViewProfile,
    required this.onReport,
    required this.onDisconnect,
  });

  final PartnerModel partner;
  final VoidCallback onViewProfile;
  final VoidCallback onReport;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Partner info header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  partner.avatarInitial.toUpperCase(),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      partner.school,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
          const SizedBox(height: 8),

          // View Profile
          _ActionTile(
            icon: Icons.person_outline_rounded,
            label: 'View Profile',
            color: cs.onSurface,
            onTap: onViewProfile,
          ),

          // Report
          _ActionTile(
            icon: Icons.flag_outlined,
            label: 'Report',
            color: cs.error,
            onTap: onReport,
          ),

          const SizedBox(height: 4),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
          const SizedBox(height: 4),

          // Disconnect — destructive action, red
          _ActionTile(
            icon: Icons.link_off_rounded,
            label: 'Disconnect',
            color: cs.error,
            isBold: true,
            onTap: onDisconnect,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
