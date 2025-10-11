import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phanplay/controllers/favourites_controller.dart';
import 'package:phanplay/screens/home_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavouritesController favouritesController = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites'), centerTitle: true),
      body: Obx(
        () => favouritesController.favouriteSongs.isEmpty
            ? Center(child: const Text('Your Favourites playlist is empty'))
            : ListView.builder(
          itemCount: favouritesController.favouriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favouritesController.favouriteSongs[index];
                  return ListTile(
                    onTap: (){
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => 
                        HomeScreen(songs: favouritesController.favouriteSongs, currentSongIndex: index))
                      );
                    },
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(Icons.audiotrack, size: 50),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(song.album ?? 'Unknown'),
                    trailing:PopupMenuButton(
                      tooltip: 'More Actions',
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text('Remove from Favourites'),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: Text('Delete'),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: Text('Add to Playlist'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
