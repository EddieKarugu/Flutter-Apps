import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static ConcatenatingAudioSource? _playlist;
  static int? _currentPlayingIndex;
  static List<SongModel>? _currentSongs;

  static AudioPlayer get audioPlayer => _audioPlayer;
  static int? get currentPlayingIndex => _currentPlayingIndex;
  static List<SongModel>? get currentSongs => _currentSongs;

  static Future<void> playNewPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
  }) async {
    // Only set a new playlist if it's actually different
    if (_currentSongs != songs || _currentPlayingIndex != initialIndex) {
      _currentSongs = songs;
      _currentPlayingIndex = initialIndex;

      _playlist = ConcatenatingAudioSource(
        children: [
          for (var song in songs) AudioSource.uri(Uri.parse(song.uri!)),
        ],
      );

      try {
        await _audioPlayer.setAudioSource(
          _playlist!,
          initialIndex: initialIndex,
          initialPosition: Duration.zero,
        );
        await _audioPlayer.play();
      } catch (e) {
        print("Error playing new playlist: $e");
      }
    } else {
      // If it's the same song, just ensure it's playing
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    }
  }
}

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
  late ConcatenatingAudioSource _playlist;
  late AudioPlayer _audioPlayer;

  int speed = 1;
  bool isMuted = false;

  bool isShuffle = false;
  bool isRepeat = false;

  // Helper to format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = MusicPlayerService.audioPlayer;
    setMusicPlayer();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSongIndex != oldWidget.currentSongIndex ||
        widget.songs != oldWidget.songs) {
      setMusicPlayer();
    }
  }

  void setMusicPlayer() async {
    _playlist = ConcatenatingAudioSource(
      children: [
        for (var song in widget.songs) AudioSource.uri(Uri.parse(song.uri!)),
      ],
    );

    try {
      await _audioPlayer.setAudioSource(
        _playlist,
        initialIndex: widget.currentSongIndex,
        initialPosition: Duration.zero,
      );
      await _audioPlayer.play();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PhanPlay'), centerTitle: true),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildArtwork(widget.songs[widget.currentSongIndex]),
                    StreamBuilder<int?>(stream: _audioPlayer.currentIndexStream, builder: (context, snapshot){
                      final currentIndex = snapshot.data ?? widget.currentSongIndex;
                      return Text(
                        widget.songs.elementAt(currentIndex).title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    StreamBuilder<int?>(
                      stream: _audioPlayer.currentIndexStream,
                      builder: (context, snapshot) {
                        final currentIndex =
                            snapshot.data ?? widget.currentSongIndex;
                        return Text(
                          widget.songs.elementAt(currentIndex).artist ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _audioPlayer.setVolume(1);
                            });
                          },
                          icon: Icon(Icons.volume_up_rounded),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isMuted = !isMuted;
                              isMuted
                                  ? _audioPlayer.setVolume(0)
                                  : _audioPlayer.setVolume(1);
                            });
                          },
                          icon: Icon(
                            Icons.volume_off,
                            color: isMuted ? Colors.deepPurple : null,
                          ),
                        ),
                        DropdownMenu(
                          dropdownMenuEntries: [
                            DropdownMenuEntry(value: 0, label: '0.5x'),
                            DropdownMenuEntry(value: 1, label: '1.0x'),
                            DropdownMenuEntry(value: 2, label: '1.5x'),
                            DropdownMenuEntry(value: 3, label: '2.0x'),
                          ],
                          hintText: 'Speed',
                          initialSelection: 1,
                          onSelected: (value) {
                            setState(() {
                              speed = value!;
                              if (speed == 0) {
                                _audioPlayer.setSpeed(.5);
                              } else if (speed == 1) {
                                _audioPlayer.setSpeed(1.0);
                              } else if (speed == 2) {
                                _audioPlayer.setSpeed(1.5);
                              } else if (speed == 3) {
                                _audioPlayer.setSpeed(2.0);
                              }
                            });
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
                                value: position.inSeconds.toDouble(),
                                onChanged: (val) {
                                  setState(() {
                                    _audioPlayer.seek(
                                      Duration(seconds: val.toInt()),
                                    );
                                  });
                                },
                                max:
                                    _audioPlayer.duration?.inSeconds
                                        .toDouble() ??
                                    1,
                                thumbColor: Colors.deepPurple,
                                activeColor: Colors.deepPurple,
                                inactiveColor: Color(0xff00eeff),
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
                            setState(() {
                              isShuffle = !isShuffle;
                            });
                            if (isShuffle) {
                              await _audioPlayer.shuffle();
                            }
                            isShuffle
                                ? await _audioPlayer.setShuffleModeEnabled(true)
                                : await _audioPlayer.setShuffleModeEnabled(
                                    false,
                                  );
                          },
                          icon: Icon(
                            Icons.shuffle,
                            size: 40,
                            color: isShuffle ? Colors.deepPurple : null,
                          ),
                        ),
                       StreamBuilder<PlayerState>(stream: _audioPlayer.playerStateStream, builder: (context, snapshot){
                         final playerState = snapshot.data;
                         final processingState = playerState?.processingState;
                         final playing = playerState?.playing;

                         if(processingState == ProcessingState.loading || processingState == ProcessingState.buffering){
                           return IconButton(
                             onPressed: (){},
                             icon: CircularProgressIndicator(
                               color: Colors.deepPurple,
                             ),
                           );
                         }
                         else{
                           if (playing != true){
                             return IconButton(
                               onPressed: (){},
                               icon: Icon(Icons.play_arrow, size: 40),
                             );
                           }
                           else{
                             return IconButton(
                               onPressed: (){},
                               icon: Icon(Icons.pause_circle, size: 40),
                             );
                           }
                         }
                       }),
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              _audioPlayer.playing;
                            });
                            _audioPlayer.playing
                                ? await _audioPlayer.pause()
                                : await _audioPlayer.play();
                          },
                          icon: Icon(
                            _audioPlayer.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 50,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _audioPlayer.seekToNext();
                            setState(() {});
                          },
                          icon: Icon(Icons.skip_next, size: 50),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.loop, size: 40),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        child: Column(children: [Text('Playlist')]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        size: 200, // Request a larger artwork size
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
