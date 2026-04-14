import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/feedback/app_snackbar.dart';
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

  /// Tracks all IDs already present in [_messages] to prevent duplicates.
  final _addedIds = <String>{};

  /// Maps temp pending IDs → index in [_messages].
  /// When Firestore confirms a message we replace the pending entry in-place.
  final _pendingMsgIds = <String>{};

  bool _isLoadingInitial = true;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  int _currentPage = 1;
  bool _canSend = false;
  bool _isDisconnected = false;

  StreamSubscription<MessageModel>? _messageSub;
  StreamSubscription<bool>? _convStatusSub;
  late final AnimationController _sendBtnCtrl;

  @override
  void initState() {
    super.initState();
    _isDisconnected = widget.chat.isDisconnected;
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadInitialMessages();
    _messageSub = ChatService.instance
        .incomingMessagesStream(widget.chat.id)
        .listen(_onIncomingMessage);
    _convStatusSub = ChatService.instance
        .conversationDisconnectedStream(widget.chat.id)
        .listen((disconnected) {
      if (!mounted) return;
      setState(() => _isDisconnected = disconnected);
      if (disconnected) {
        _sendBtnCtrl.reverse();
      } else if (_inputCtrl.text.trim().isNotEmpty) {
        _sendBtnCtrl.forward();
      }
    });
    _inputCtrl.addListener(() {
      final canSend = _inputCtrl.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
        if (canSend && !_isDisconnected) {
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
    _convStatusSub?.cancel();
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
    // Reset unread badge when opening chat.
    ChatService.instance.resetUnreadCount(widget.chat.id);
    if (!mounted) return;
    setState(() {
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
      // Insert only messages not already shown (dedup by ID).
      final newOlder = older.where((m) => _addedIds.add(m.id)).toList();
      _messages.insertAll(0, newOlder);
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
    if (_isDisconnected) {
      final l = AppLocalizations.of(context)!;
      showErrorTextSnackBar(context, l.chatSendBlockedDisconnected);
      return;
    }
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
    if (_isDisconnected) {
      final l = AppLocalizations.of(context)!;
      showErrorTextSnackBar(context, l.chatSendBlockedDisconnected);
      return;
    }
    HapticFeedback.lightImpact();
    final tempId =
        'pending_loc_${DateTime.now().microsecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      senderId: _myUid(),
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
    if (_isDisconnected) {
      final l = AppLocalizations.of(context)!;
      showErrorTextSnackBar(context, l.chatSendBlockedDisconnected);
      return;
    }
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
      senderId: _myUid(),
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

  /// Current user's UID — safe fallback to 'me'.
  String _myUid() {
    // ignore: unnecessary_import — firebase_auth is a transitive dep already
    return (FirebaseAuth.instance.currentUser?.uid) ?? 'me';
  }

  Future<void> _confirmDisconnect() async {
    final l = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.chatDisconnectConfirmTitle),
        content: Text(l.chatDisconnectConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.chatDisconnectMenu),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await ChatService.instance.disconnectConversation(widget.chat.id);
    if (mounted) showSuccessSnackBar(context, l.chatDisconnectSuccess);
  }

  Future<void> _onReconnect() async {
    final l = AppLocalizations.of(context)!;
    await ChatService.instance.reconnectConversation(widget.chat.id);
    if (mounted) showSuccessSnackBar(context, l.chatReconnectSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final partner = widget.chat.partner;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: _buildAppBar(partner),
      body: Column(
        children: [
          if (_isDisconnected)
            _DisconnectBanner(
              message: l.chatDisconnectedBanner,
              reconnectLabel: l.chatReconnect,
              onReconnect: _onReconnect,
            ),
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
          icon: Icon(Icons.more_vert_rounded,
              color: onS, size: 22),
          onPressed: () => _showOptions(context, partner),
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
    final locked = _isDisconnected;
    final canSendNow = _canSend && !locked;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Container(
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
                onPressed: locked ? null : _showAttachSheet,
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
                  readOnly: locked,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: context.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: locked
                        ? AppLocalizations.of(context)!.chatSendBlockedDisconnected
                        : 'Type a message…',
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
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text('View Profile',
                  style: GoogleFonts.notoSansKr(fontSize: 14)),
              onTap: () => Navigator.pop(sheetCtx),
            ),
            ListTile(
              leading: Icon(Icons.pause_circle_outline_rounded,
                  color: context.onSurfaceVar),
              title: Text(
                l.chatDisconnectMenu,
                style: GoogleFonts.notoSansKr(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDisconnect();
              },
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

// ─────────────────────────── Disconnect banner ───────────────────────────
class _DisconnectBanner extends StatelessWidget {
  const _DisconnectBanner({
    required this.message,
    required this.reconnectLabel,
    required this.onReconnect,
  });

  final String message;
  final String reconnectLabel;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    return Material(
      color: context.cs.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: p),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: context.onSurface,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(
              onPressed: onReconnect,
              child: Text(
                reconnectLabel,
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w700,
                  color: p,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final cs = Theme.of(context).colorScheme;
    final myBg = cs.primary;
    final partnerBg = context.cardFill;
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
          color: isMe ? myBg : partnerBg,
          borderRadius: borderRadius,
          boxShadow: isMe ? null : context.cardElevationShadow,
        ),
        child: Text(
          message.content,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: isMe ? cs.onPrimary : context.onSurface,
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

  Future<void> _open() async {
    final uri = Uri.parse(
        'https://maps.google.com/?q=${location.lat},${location.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.primary;
    final bg = isMe ? cs.primary : context.cardFill;
    final text = isMe ? cs.onPrimary : context.onSurface;
    final sub = isMe ? cs.onPrimary.withValues(alpha: 0.75) : context.onSurfaceVar;

    return GestureDetector(
      onTap: _open,
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
                        Icon(Icons.open_in_new_rounded,
                            size: 12,
                            color: isMe ? cs.onPrimary : p),
                        const SizedBox(width: 4),
                        Text('Open in Maps',
                            style: GoogleFonts.notoSansKr(
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
    final p = context.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: p, size: 20),
                const SizedBox(width: 8),
                Text('Share a Location',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.onSurface)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...locations.map((loc) => ListTile(
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
                title: Text(loc.name,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.onSurface)),
                subtitle: loc.address.isNotEmpty
                    ? Text(loc.address,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12, color: context.onSurfaceVar),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                    : null,
                onTap: () => Navigator.pop(context, loc),
              )),
        ],
      ),
    );
  }
}
