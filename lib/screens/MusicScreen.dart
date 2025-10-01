import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phanplay/screens/home_screen.dart';
import '../Initializers/user_shared_preferences.dart';
import '../controllers/ThemeController.dart';
import '../widgets/customTextField.dart';

class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  _SongsState createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final TextEditingController _searchController = TextEditingController();
  bool _hasPermission = false;

  // 1. Add a list to hold all songs
  List<SongModel> _allSongs = [];
  // 2. Add a list to hold the currently displayed (filtered) songs
  List<SongModel> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);

    // Check and request for permission.
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _audioQuery.checkAndRequest(retryRequest: retry);

    // Only call update the UI if application has all required permissions.
    _hasPermission ? setState(() {}) : null;
  }

  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }

  void _filterSongs(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredSongs = List.from(_allSongs); // Show all songs if search is empty
      } else {
        _filteredSongs = _allSongs
            .where((song) =>
        song.title.toLowerCase().contains(searchText.toLowerCase()) ||
            (song.artist?.toLowerCase().contains(searchText.toLowerCase()) ?? false)) // Also search by artist
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/phanplay.png',
            height: 24,
            width: 24,
          ),
        ),
        title: const Text("PhanPlay"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                ThemeController.isLightTheme.value =
                    !ThemeController.isLightTheme.value;
                UserSharedPrefs.prefs!.setBool(
                  'PhanPlayIsLightMode',
                  ThemeController.isLightTheme.value,
                );
              });
            },
            icon: Icon(
              ThemeController.isLightTheme.value
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
        ],
        elevation: 2,
      ),
      body: Center(
        child: !_hasPermission
            ? noAccessToLibraryWidget()
            : FutureBuilder<List<SongModel>>(
                // Default values:
                future: _audioQuery.querySongs(
                  sortType: null,
                  orderType: OrderType.ASC_OR_SMALLER,
                  uriType: UriType.EXTERNAL,
                  ignoreCase: true,
                ),
                builder: (context, item) {
                  // Display error, if any.
                  if (item.hasError) {
                    return Text(item.error.toString());
                  }

                  // Waiting content.
                  if (item.data == null) {
                    return const CircularProgressIndicator();
                  }

                  // 'Library' is empty.
                  if (item.data!.isEmpty) return const Text("Nothing found!");

                  if (_allSongs.isEmpty && item.data != null) {
                    _allSongs = item.data!;
                    _filteredSongs = List.from(_allSongs); // Initially show all songs
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Customtextfield(
                          hint: 'Search music here',
                          icon: Icons.search,
                          controller: _searchController,
                          onChanged: (String text) {
                            setState(() {
                              _filteredSongs = _allSongs
                                  .where(
                                    (song) => song.title.toLowerCase().contains(
                                      text.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _filteredSongs.isEmpty? const Center(child: Text('No Songs Found'),)
                        :
                        ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final songs = _filteredSongs;

                            return ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(
                                      songs: songs,
                                      currentSongIndex: index,
                                    ),
                                  ),
                                );
                              },
                              title: Text(
                                songs[index].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                songs[index].artist ?? "No Artist",
                              ),
                              trailing: const Icon(Icons.more_vert),

                              // This Widget will query/load image.
                              // You can use/create your own widget/method using [queryArtwork].
                              leading: QueryArtworkWidget(
                                controller: _audioQuery,
                                id: songs[index].id,
                                type: ArtworkType.AUDIO,
                                size: 100,
                                nullArtworkWidget: CircleAvatar(
                                  radius: 28,
                                  child: const Icon(Icons.music_note),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.deepPurple,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
