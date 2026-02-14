/// Quick Reference: Agora Voice/Video Room Integration
///
/// This file demonstrates how to use the new Agora service with
/// participant and video tile providers.
///
/// ============================================================================
/// SETUP (in your room page)
/// ============================================================================
///
/// ```dart
/// class VoiceRoomPage extends ConsumerStatefulWidget {
///   final Room room;
///   const VoiceRoomPage({required this.room});
/// }
///
/// class _VoiceRoomPageState extends ConsumerState<VoiceRoomPage> {
///   late final AgoraVideoService _agoraService;
///
///   @override
///   void initState() {
///     super.initState();
///     _agoraService = ref.read(agoraVideoServiceProvider);
///     _initializeAndJoin();
///   }
///
///   Future<void> _initializeAndJoin() async {
///     try {
///       // 1. Initialize Agora (registers all event handlers)
///       await _agoraService.initialize();
///
///       // 2. Join the room
///       await _agoraService.joinRoom(widget.room.id);
///     } catch (e) {
///       // Handle error
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Failed to join room: $e')),
///       );
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     // Watch participants state
///     final participants = ref.watch(agoraParticipantsProvider);
///
///     // Watch video tiles
///     final videoTiles = ref.watch(videoTileProvider);
///
///     return Scaffold(
///       appBar: AppBar(
///         title: Text(widget.room.name),
///         actions: [
///           // Mic toggle
///           IconButton(
///             icon: Icon(_agoraService.isMicMuted ? Icons.mic_off : Icons.mic),
///             onPressed: () => _agoraService.toggleMic(),
///           ),
///
///           // Video toggle
///           IconButton(
///             icon: Icon(_agoraService.isVideoMuted ? Icons.videocam_off : Icons.videocam),
///             onPressed: () => _agoraService.toggleVideo(),
///           ),
///         ],
///       ),
///       body: Column(
///         children: [
///           // Video grid (if video enabled)
///           if (videoTiles.videoCount > 0)
///             Expanded(
///               child: GridView.builder(
///                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///                   crossAxisCount: 2,
///                 ),
///                 itemCount: videoTiles.allVideoUids.length,
///                 itemBuilder: (context, index) {
///                   final uid = videoTiles.allVideoUids[index];
///                   return _buildVideoTile(uid);
///                 },
///               ),
///             ),
///
///           // Participant list
///           _buildParticipantList(participants),
///         ],
///       ),
///     );
///   }
///
///   Widget _buildVideoTile(int uid) {
///     final isLocal = uid == _agoraService.localUid;
///
///     return Stack(
///       children: [
///         AgoraVideoView(
///           controller: isLocal
///               ? VideoViewController(
///                   rtcEngine: _agoraService.engine!,
///                   canvas: const VideoCanvas(uid: 0),
///                 )
///               : VideoViewController.remote(
///                   rtcEngine: _agoraService.engine!,
///                   canvas: VideoCanvas(uid: uid),
///                   connection: RtcConnection(channelId: _agoraService.currentChannel!),
///                 ),
///         ),
///
///         // Display name overlay
///         Positioned(
///           bottom: 8,
///           left: 8,
///           child: _buildUserNameTag(uid),
///         ),
///       ],
///     );
///   }
///
///   Widget _buildUserNameTag(int uid) {
///     final participant = ref.watch(agoraParticipantsProvider)[uid];
///
///     return Container(
///       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
///       decoration: BoxDecoration(
///         color: Colors.black54,
///         borderRadius: BorderRadius.circular(4),
///       ),
///       child: Row(
///         mainAxisSize: MainAxisSize.min,
///         children: [
///           // Speaking indicator
///           if (participant?.isSpeaking == true)
///             Icon(Icons.graphic_eq, color: Colors.green, size: 16),
///
///           SizedBox(width: 4),
///
///           // Display name
///           Text(
///             participant?.displayName ?? 'Loading...',
///             style: TextStyle(color: Colors.white, fontSize: 12),
///           ),
///         ],
///       ),
///     );
///   }
///
///   Widget _buildParticipantList(Map<int, AgoraParticipant> participants) {
///     return Container(
///       height: 200,
///       child: ListView.builder(
///         itemCount: participants.length,
///         itemBuilder: (context, index) {
///           final participant = participants.values.elementAt(index);
///           return ListTile(
///             leading: CircleAvatar(
///               child: Text(participant.displayName[0].toUpperCase()),
///             ),
///             title: Text(participant.displayName),
///             trailing: Row(
///               mainAxisSize: MainAxisSize.min,
///               children: [
///                 // Mic indicator
///                 Icon(
///                   participant.hasAudio ? Icons.mic : Icons.mic_off,
///                   color: participant.hasAudio ? Colors.green : Colors.red,
///                 ),
///                 SizedBox(width: 8),
///
///                 // Camera indicator
///                 Icon(
///                   participant.hasVideo ? Icons.videocam : Icons.videocam_off,
///                   color: participant.hasVideo ? Colors.green : Colors.red,
///                 ),
///
///                 // Speaking indicator
///                 if (participant.isSpeaking)
///                   Padding(
///                     padding: EdgeInsets.only(left: 8),
///                     child: Icon(Icons.graphic_eq, color: Colors.green),
///                   ),
///               ],
///             ),
///           );
///         },
///       ),
///     );
///   }
///
///   @override
///   void dispose() {
///     _agoraService.leaveRoom();
///     super.dispose();
///   }
/// }
/// ```
///
/// ============================================================================
/// KEY FEATURES NOW AVAILABLE
/// ============================================================================
///
/// ✅ Participant list with real-time updates
/// ✅ Display names fetched from Firestore (cached)
/// ✅ Camera on/off indicators
/// ✅ Mic on/off indicators
/// ✅ Speaking indicators (volume-based)
/// ✅ Video tiles automatically managed
/// ✅ Clean event-driven architecture
/// ✅ Full debug logging
///
/// ============================================================================
/// DEBUGGING
/// ============================================================================
///
/// All Agora events are logged with emojis:
/// - 🎥 Initialization
/// - ✅ Success
/// - ❌ Errors
/// - 👤 User join/leave
/// - 📹 Video state changes
/// - 🎤 Audio state changes
/// - 🔌 Connection state
/// - ⚠️  Warnings
///
/// Check your console for these logs to troubleshoot issues.
///
library;
