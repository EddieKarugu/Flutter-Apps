import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phanplay/controllers/ThemeController.dart';
import 'package:phanplay/controllers/favourites_controller.dart';
import '../Initializers/musicPlayerService.dart';
import 'package:get/get.dart';

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
  late AudioPlayer _audioPlayer;
  late PageController _pageController; // Add PageController

  int speed = 1;
  bool isMuted = false;
  bool isShuffle = false;
  bool isRepeat = false;
  bool isLooping = false;

  int _currentPageIndex = -1;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = MusicPlayerService.audioPlayer;

    // Initialize PageController with the current song index
    _pageController = PageController(initialPage: widget.currentSongIndex);

    _playInitialMusic();

    _audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      if (mounted) {
        setState(() {
          isShuffle = enabled;
        });
      }
    });

    _audioPlayer.loopModeStream.listen((loopMode) {
      if (mounted) {
        setState(() {
          isLooping = loopMode == LoopMode.one;
        });
      }
    });

    // Listen to the audio player's current index stream
    // and update the PageController if the player changes song outside of a swipe (e.g., auto-play next)
    _audioPlayer.currentIndexStream.listen((playerIndex) {
      if (mounted && playerIndex != null && playerIndex != _currentPageIndex) {
        _currentPageIndex = playerIndex; // Update our internal tracker
        _pageController.animateToPage(
          playerIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  void _playInitialMusic() async {
    await MusicPlayerService.playNewPlaylist(
      songs: widget.songs,
      initialIndex: widget.currentSongIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FavouritesController favouritesController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhanPlay'),
        centerTitle: true,
        actions: [
          // This StreamBuilder ensures the star icon updates when the song changes via swipe
          StreamBuilder<int?>(
            stream: _audioPlayer.currentIndexStream,
            builder: (context, snapshot) {
              final int? currentIndex = snapshot.data;
              final List<SongModel>? currentPlaylistSongs = MusicPlayerService.currentSongs;

              if (currentIndex == null || currentPlaylistSongs == null || currentIndex >= currentPlaylistSongs.length) {
                return IconButton( // Placeholder for when no song is loaded
                  onPressed: null,
                  icon: Icon(Icons.star_border),
                );
              }

              final SongModel currentSong = currentPlaylistSongs[currentIndex];
              bool isStarred = favouritesController.favouriteSongs.contains(currentSong);

              return IconButton(
                onPressed: () {
                  isStarred
                      ? favouritesController.removeFavourites(currentSong)
                      : favouritesController.addFavourite(currentSong);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1000),
                      content: Text(
                        isStarred
                            ? 'Removed from Favourites'
                            : 'Added to Favourites',
                      ),
                    ),
                  );
                  // Update the UI immediately after changing favorite status
                  setState(() {});
                },
                icon: Icon(isStarred ? Icons.star : Icons.star_border),
              );
            },
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
              // Use PageView.builder for the song-specific content
              Expanded( // Ensure PageView takes available space
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.songs.length, // Number of songs in the playlist
                  onPageChanged: (index) {
                    // This is crucial: when the page changes, tell the audio player to seek to that song
                    MusicPlayerService.seekToIndex(index);
                  },
                  itemBuilder: (context, index) {
                    // Build the content for each song page
                    final SongModel song = widget.songs[index];
                    return Column(
                      children: [
                        _buildArtwork(song), // Artwork for the current song
                        const SizedBox(height: 16),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ThemeController.isLightTheme.value
                                ? Colors.black
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ThemeController.isLightTheme.value
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 26),
                        // ... (Other controls like volume, speed, slider, buttons will be below PageView)
                        // Make sure these controls are *outside* the PageView.builder's item build
                        // so they apply to the currently playing song, not just the currently displayed page.
                      ],
                    );
                  },
                ),
              ),
              // The rest of your controls that apply to the player's state (not specific page content)
              // should be outside the PageView.builder, but still within the main Column.
              // They will react to the _audioPlayer.currentIndexStream which updates when onPageChanged is called.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _audioPlayer.setVolume(1.0);
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
                  DropdownMenu(
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 0.5, label: '0.5x'),
                      DropdownMenuEntry(value: 1.0, label: '1.0x'),
                      DropdownMenuEntry(value: 1.5, label: '1.5x'),
                      DropdownMenuEntry(value: 2.0, label: '2.0x'),
                    ],
                    hintText: 'Speed',
                    initialSelection:
                    _audioPlayer.speed,
                    onSelected: (value) {
                      if (value != null) {
                        _audioPlayer.setSpeed(value);
                        if (mounted) {
                          setState(() {
                            // Update local state if necessary for display
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
                  IconButton(
                    onPressed: () async {
                      await _audioPlayer.setShuffleModeEnabled(
                        !_audioPlayer.shuffleModeEnabled,
                      );
                    },
                    icon: Icon(
                      Icons.shuffle,
                      size: 40,
                      color: isShuffle ? Colors.deepPurple : null,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      // This will also trigger onPageChanged via currentIndexStream listener
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
                  IconButton(
                    onPressed: () async {
                      // This will also trigger onPageChanged via currentIndexStream listener
                      await MusicPlayerService.seekToNext();
                    },
                    icon: const Icon(Icons.skip_next, size: 50),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (_audioPlayer.loopMode == LoopMode.off) {
                        await _audioPlayer.setLoopMode(LoopMode.one);
                      } else if (_audioPlayer.loopMode == LoopMode.one) {
                        await _audioPlayer.setLoopMode(LoopMode.all);
                      } else {
                        await _audioPlayer.setLoopMode(LoopMode.off);
                      }
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(SongModel song) { // Changed to non-nullable as song is guaranteed in PageView.builder
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