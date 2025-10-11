import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phanplay/Initializers/user_shared_preferences.dart';

class FavouritesController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    loadFavourites();
  }

  var favouriteSongs = <SongModel>[].obs;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<void> loadFavourites() async {
    final List<String>? favouriteIdsJson = UserSharedPrefs.prefs?.getStringList('favouriteSongs');

    if (favouriteIdsJson != null && favouriteIdsJson.isNotEmpty) {
      // Convert JSON strings back to a list of integer IDs
      final List<int> favouriteIds = favouriteIdsJson.map(int.parse).toList();

      final List<SongModel> allSongs = await _audioQuery.querySongs();
      final List<SongModel> loadedFavourites = [];

      for (int id in favouriteIds) {
        final SongModel? song = allSongs.firstWhereOrNull((s) => s.id == id);
        if (song != null) {
          loadedFavourites.add(song);
        }
      }
      favouriteSongs.assignAll(loadedFavourites);
    }
  }

  void addFavourite(SongModel song) async {
    favouriteSongs.add(song);
    await UserSharedPrefs.prefs.setStringList(
      'favouriteSongs',
      favouriteSongs.map((song) => song.id.toString()).toList(),
    );
  }

  void removeFavourites(SongModel song) async{
    favouriteSongs.remove(song);
    await UserSharedPrefs.prefs?.setStringList(
      'favouriteSongs',
      favouriteSongs.map((song) => song.id.toString()).toList(),
    );
  }
}
