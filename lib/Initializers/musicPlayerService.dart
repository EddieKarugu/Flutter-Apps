import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart'; // Import for ValueNotifier
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Centralized controller for the current music index
class PositionController {
  static ValueNotifier<int?> currentMusic = ValueNotifier(null);
}

class MusicPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static ConcatenatingAudioSource? _playlist;
  static List<SongModel>? _currentSongs;

  static AudioPlayer get audioPlayer => _audioPlayer;
  static List<SongModel>? get currentSongs => _currentSongs;

  // Static constructor or init method to set up listeners
  static void init() {
    // Listen to changes in the player's current index
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && PositionController.currentMusic.value != index) {
        PositionController.currentMusic.value = index;
      }
    });

    // Optionally, listen to playback state changes if you need to update UI based on play/pause
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Handle end of playlist, e.g., reset index or do something else
        if (_audioPlayer.loopMode == LoopMode.all ||
            _audioPlayer.shuffleModeEnabled) {
          // Player will automatically go to next or loop
        } else if (_audioPlayer.currentIndex ==
            (_audioPlayer.sequence?.length ?? 1) - 1) {
          // Last song, not looping, so set currentMusic to null or reset
          PositionController.currentMusic.value = null;
        }
      }
    });
  }

  static Future<void> playNewPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
  }) async {
    // Check if the current playlist is actually different
    // We compare URIs for uniqueness, as SongModel objects themselves might be different instances
    final newSongUris = songs.map((s) => s.uri).toList();
    final currentSongUris = _currentSongs?.map((s) => s.uri).toList();

    bool isNewPlaylist = false;
    if (_currentSongs == null || _currentSongs!.length != songs.length) {
      isNewPlaylist = true;
    } else {
      for (int i = 0; i < songs.length; i++) {
        if (_currentSongs![i].uri != songs[i].uri) {
          isNewPlaylist = true;
          break;
        }
      }
    }

    if (isNewPlaylist || _audioPlayer.currentIndex != initialIndex) {
      _currentSongs = songs; // Store the new list
      PositionController.currentMusic.value =
          initialIndex; // Update the global notifier

      _playlist = ConcatenatingAudioSource(
        children: [
          for (var song in songs)
            AudioSource.uri(
              Uri.parse(song.uri!),
              tag: MediaItem(id: song.id.toString(),
                  title: song.title,
                artist: song.artist,
                album: song.album
              ),
            ),
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
      // If it's the same song being tapped again or already playing, just ensure it's playing
      if (!_audioPlayer.playing) {
        await _audioPlayer.play();
      } else if (_audioPlayer.currentIndex != initialIndex) {
        // If the same playlist, but a different initial index was requested
        await _audioPlayer.seek(Duration.zero, index: initialIndex);
        await _audioPlayer.play();
        PositionController.currentMusic.value = initialIndex;
      } else {
        print(
          "MusicPlayerService: Already playing current song at index $initialIndex",
        );
      }
    }
  }

  // Add next and previous methods to the service
  static Future<void> seekToNext() async {
    await audioPlayer.seekToNext();
    PositionController.currentMusic.value! > _currentSongs!.length
        ? PositionController.currentMusic.value =
              PositionController.currentMusic.value! - 1
        : PositionController.currentMusic.value = 0;
  }

  static Future<void> seekToPrevious() async {
    await audioPlayer.seekToPrevious();
    PositionController.currentMusic.value! > 0
        ? PositionController.currentMusic.value =
              PositionController.currentMusic.value! - 1
        : PositionController.currentMusic.value = 0;
  }

  static Future<void> seekToIndex(int index) async {
    if (_audioPlayer.currentIndex != index) {
      await _audioPlayer.seek(Duration.zero, index: index);
      // Ensure the service's internal state reflects the new song
      if (currentSongs != null && index < currentSongs!.length) {
        // You might want to update a currentSong variable in the service if you have one
        // For now, just_audio's internal index will handle it.
        PositionController.currentMusic.value = index;
      }
    }
  }

  static Future<int?> seekWithName (String songName) async{
    final index = _currentSongs!.indexWhere((song) => song.title == songName);
    return index;
  }

  // And make sure your seekToNext and seekToPrevious methods also appropriately update the index.
  // just_audio's `seekToNext()` and `seekToPrevious()` naturally update the `currentIndexStream`
  // so the PageView will respond via the listener.
}
