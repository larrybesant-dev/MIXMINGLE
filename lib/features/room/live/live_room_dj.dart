// lib/features/room/live/live_room_dj.dart
//
// Preset track list for the in-room DJ panel.
// Replace URLs with your licensed tracks before production release.
// ───────────────────────────────────────────────────────────────────────────

typedef DjTrack = ({String title, String url});

const List<DjTrack> kDjPresetTracks = [
  (
    title: 'Lofi Chill – Study Beats',
    url: 'https://cdn.pixabay.com/audio/2024/02/15/audio_a98186bc4c.mp3',
  ),
  (
    title: 'Upbeat Energy Dance',
    url: 'https://cdn.pixabay.com/audio/2023/09/22/audio_23c5bb0e7f.mp3',
  ),
  (
    title: 'Chillout Ambient',
    url: 'https://cdn.pixabay.com/audio/2023/05/07/audio_949bfab4e7.mp3',
  ),
  (
    title: 'Hip Hop Groove',
    url: 'https://cdn.pixabay.com/audio/2022/10/11/audio_e3d293b2d7.mp3',
  ),
  (
    title: 'Smooth Jazz Café',
    url: 'https://cdn.pixabay.com/audio/2023/02/28/audio_bb8b4b5b3b.mp3',
  ),
];
