import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FavouritesController extends GetxController{
  var favouriteSongs = <SongModel>[].obs;

  void addFavourite(SongModel song){
    favouriteSongs.add(song);
  }
  void removeFavourites(SongModel song){
    favouriteSongs.remove(song);
  }
}