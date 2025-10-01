import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phanplay/controllers/ThemeController.dart';
import '../Initializers/musicPlayerService.dart';

class HomeScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int currentSongIndex;

  const HomeScreen({
    super.key,
    required this.songs,
    required this.currentSongIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Get the audio player instance from the service
  late AudioPlayer _audioPlayer;

  // State variables for UI
  int speed = 1;
  bool isMuted = false;
  bool isStarred = false;
  bool isShuffle = false; // Just_audio handles shuffle internally
  bool isRepeat = false; // This is redundant if you use LoopMode.one
  bool isLooping = false; // Just_audio handles loop mode

  // Helper to format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    // Only show hours if duration is greater than an hour
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = MusicPlayerService.audioPlayer;
    // Initial call to play the music via the service
    _playInitialMusic();
    // Listen to shuffle mode changes from the player
    _audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      if (mounted) {
        setState(() {
          isShuffle = enabled;
        });
      }
    });
    // Listen to loop mode changes from the player
    _audioPlayer.loopModeStream.listen((loopMode) {
      if (mounted) {
        setState(() {
          isLooping = loopMode == LoopMode.one;
        });
      }
    });
  }

  void _playInitialMusic() async {
    // Let the service handle playing the music.
    // It will check if it's a new playlist/song or just needs to resume.
    await MusicPlayerService.playNewPlaylist(
      songs: widget.songs,
      initialIndex: widget.currentSongIndex,
    );
  }

  // No need for didUpdateWidget to re-set the player,
  // as the service manages it based on playNewPlaylist.

  @override
  void dispose() {
    // Do not dispose _audioPlayer here, as it's managed by the service.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhanPlay'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isStarred = !isStarred;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1000),
                    content: Text(
                      isStarred
                          ? 'Added to Favourites'
                          : 'Removed from Favourites',
                    ),
                  ),
                );
              });
            },
            icon: Icon(isStarred ? Icons.star : Icons.star_border),
          ),
        ],
      ),
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Colors.transparent,
          image: DecorationImage(
            image: AssetImage('assets/images/phanplay.png'),
            fit: BoxFit.cover,
            opacity: .3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              StreamBuilder<int?>(
                stream: _audioPlayer.currentIndexStream,
                builder: (context, snapshot) {
                  // Get current index from the player's stream
                  final int? currentIndex = snapshot.data;
                  // Get the current song list from the service (which should be in sync)
                  final List<SongModel>? currentPlaylistSongs =
                      MusicPlayerService.currentSongs;

                  if (currentIndex == null ||
                      currentPlaylistSongs == null ||
                      currentIndex >= currentPlaylistSongs.length) {
                    return _buildArtwork(
                      null,
                    ); // Or a loading/placeholder state
                  }
                  final SongModel currentSong =
                      currentPlaylistSongs[currentIndex];
                  return _buildArtwork(currentSong);
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<int?>(
                stream: _audioPlayer.currentIndexStream,
                builder: (context, snapshot) {
                  final int? currentIndex = snapshot.data;
                  final List<SongModel>? currentPlaylistSongs =
                      MusicPlayerService.currentSongs;

                  if (currentIndex == null ||
                      currentPlaylistSongs == null ||
                      currentIndex >= currentPlaylistSongs.length) {
                    return const Text("Loading...");
                  }
                  final SongModel currentSong =
                      currentPlaylistSongs[currentIndex];
                  return Text(
                    currentSong.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeController.isLightTheme.value
                          ? Colors.black
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              StreamBuilder<int?>(
                stream: _audioPlayer.currentIndexStream,
                builder: (context, snapshot) {
                  final int? currentIndex = snapshot.data;
                  final List<SongModel>? currentPlaylistSongs =
                      MusicPlayerService.currentSongs;

                  if (currentIndex == null ||
                      currentPlaylistSongs == null ||
                      currentIndex >= currentPlaylistSongs.length) {
                    return const Text("Unknown Artist");
                  }
                  final SongModel currentSong =
                      currentPlaylistSongs[currentIndex];
                  return Text(
                    currentSong.artist ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeController.isLightTheme.value
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      fontSize: 16,
                    ),
                  );
                },
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Volume Up (if you want this, it's not standard)
                  IconButton(
                    onPressed: () {
                      _audioPlayer.setVolume(1.0); // Set to max volume
                      if (mounted) {
                        setState(() {
                          isMuted = false;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: isMuted ? Colors.grey : null,
                    ),
                  ),
                  // Mute/Unmute
                  IconButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          isMuted = !isMuted;
                          isMuted
                              ? _audioPlayer.setVolume(0)
                              : _audioPlayer.setVolume(1);
                        });
                      }
                    },
                    icon: Icon(
                      Icons.volume_off,
                      color: isMuted ? Colors.deepPurple : null,
                    ),
                  ),
                  // Playback Speed
                  DropdownMenu(
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 0.5, label: '0.5x'),
                      DropdownMenuEntry(value: 1.0, label: '1.0x'),
                      DropdownMenuEntry(value: 1.5, label: '1.5x'),
                      DropdownMenuEntry(value: 2.0, label: '2.0x'),
                    ],
                    hintText: 'Speed',
                    initialSelection:
                        _audioPlayer.speed, // Use current player speed
                    onSelected: (value) {
                      if (value != null) {
                        _audioPlayer.setSpeed(value);
                        if (mounted) {
                          setState(() {
                            // You might want to update a local state variable for display if needed
                            // For now, _audioPlayer.speed will reflect the current speed
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              StreamBuilder<Duration?>(
                stream: _audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = _audioPlayer.duration ?? Duration.zero;

                  return Row(
                    children: [
                      Text(_formatDuration(position)),
                      Expanded(
                        child: Slider(
                          value: position.inSeconds.toDouble().clamp(
                            0.0,
                            duration.inSeconds.toDouble(),
                          ),
                          onChanged: (val) {
                            _audioPlayer.seek(Duration(seconds: val.toInt()));
                          },
                          min: 0.0,
                          max: duration.inSeconds.toDouble(),
                          thumbColor: Colors.deepPurple,
                          activeColor: Colors.deepPurple,
                        ),
                      ),
                      Text(_formatDuration(duration)),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shuffle Button
                  IconButton(
                    onPressed: () async {
                      await _audioPlayer.setShuffleModeEnabled(
                        !_audioPlayer.shuffleModeEnabled,
                      );
                      // State update for UI happens via the _audioPlayer.shuffleModeEnabledStream listener in initState
                    },
                    icon: Icon(
                      Icons.shuffle,
                      size: 40,
                      color: isShuffle ? Colors.deepPurple : null,
                    ),
                  ),
                  // Previous Button
                  IconButton(
                    onPressed: () async {
                      await MusicPlayerService.seekToPrevious();
                    },
                    icon: const Icon(Icons.skip_previous, size: 50),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;

                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) {
                        return const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        );
                      } else {
                        if (playing != true) {
                          return IconButton(
                            onPressed: () {
                              _audioPlayer.play();
                            },
                            icon: const Icon(Icons.play_arrow, size: 40),
                          );
                        } else {
                          return IconButton(
                            onPressed: () {
                              _audioPlayer.pause();
                            },
                            icon: const Icon(Icons.pause_circle, size: 40),
                          );
                        }
                      }
                    },
                  ),
                  // Next Button
                  IconButton(
                    onPressed: () async {
                      await MusicPlayerService.seekToNext();
                    },
                    icon: const Icon(Icons.skip_next, size: 50),
                  ),
                  // Loop/Repeat Button
                  IconButton(
                    onPressed: () async {
                      if (_audioPlayer.loopMode == LoopMode.off) {
                        await _audioPlayer.setLoopMode(LoopMode.one);
                      } else if (_audioPlayer.loopMode == LoopMode.one) {
                        await _audioPlayer.setLoopMode(LoopMode.all);
                      } else {
                        await _audioPlayer.setLoopMode(LoopMode.off);
                      }
                      // State update for UI happens via the _audioPlayer.loopModeStream listener in initState
                    },
                    icon: Icon(
                      Icons.loop,
                      size: 40,
                      color: _audioPlayer.loopMode == LoopMode.one
                          ? Colors.deepPurple
                          : (_audioPlayer.loopMode == LoopMode.all
                                ? Colors.blue
                                : null),
                    ),
                  ),
                ],
              ),
              Expanded(child: Column(children: const [Text('Playlist')])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(SongModel? song) {
    if (song == null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.music_note, size: 100, color: Colors.grey[600]),
      );
    }
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        artworkFit: BoxFit.cover,
        size: 200,
        quality: 100,
        nullArtworkWidget: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Icon(Icons.music_note, size: 100)),
        ),
      ),
    );
  }
}
