# Audio Assets

Place your audio files here. The app expects the following files:

## Required files

| File | Description | Duration |
|------|-------------|----------|
| `intro_sting.mp3` | Landing page intro sting – neon "whoosh" or pulse | 0.5–1 s |
| `ambient_loop.mp3` | Landing page ambient loop – seamless loop | 3–10 s |
| `join_room.mp3` | Soft chime when a user joins a room | < 0.5 s |
| `new_speaker.mp3` | Tiny "ping" when a new speaker starts talking | < 0.3 s |
| `energy_spike.mp3` | Low bass pulse when room energy crosses a threshold | < 0.5 s |
| `reaction.mp3` | Soft click/pop when a reaction is sent | < 0.3 s |

## Notes
- Keep all files below 500 KB for fast load on web.
- MP3 is recommended for broad browser support.
- Use stereo 44 100 Hz, 128 kbps for music; 44 100 Hz, 96 kbps for SFX.
- Sounds will play at reduced volume (see `SoundEffectsService`).
