import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phanplay/Initializers/user_shared_preferences.dart';
import 'package:phanplay/controllers/ThemeController.dart';
import 'package:just_audio/just_audio.dart';

class HomeScreen extends StatefulWidget {
  final String audio;
  final String name;
  const HomeScreen({super.key, required this.audio, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final player = AudioPlayer();
  int speed = 1;
  bool isMuted = false;

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
    setMusicPlayer();
  }

  void setMusicPlayer() async{
    if(player.playing){
      await player.dispose();
    }
    await player.setFilePath(widget.audio);
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (player.playing) {
      setState(() {
        player.position;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhanPlay'),
        centerTitle: true,

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      widget.name ?? 'Music Name here',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(player.icyMetadata?.headers?.genre ?? 'Genre'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              player.setVolume(1);
                            });
                          },
                          icon: Icon(Icons.volume_up_rounded),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isMuted = !isMuted;
                              isMuted? player.setVolume(0): player.setVolume(1);
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
                                player.setSpeed(.5);
                              } else if (speed == 1) {
                                player.setSpeed(1.0);
                              } else if (speed == 2) {
                                player.setSpeed(1.5);
                              } else if (speed == 3) {
                                player.setSpeed(2.0);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    StreamBuilder<Duration?>(
                      stream: player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = player.duration ?? Duration.zero;

                        return Row(
                          children: [
                            Text(_formatDuration(position)),
                            Expanded(
                              child: Slider(
                                value: position.inSeconds.toDouble(),
                                onChanged: (val) {
                                  setState(() {
                                    player.seek(Duration(seconds: val.toInt()));
                                  });
                                },
                                max: player.duration?.inSeconds.toDouble() ?? 1,
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
                          onPressed: () async{
                            await player.shuffle();
                          },
                          icon: Icon(Icons.shuffle, size: 40),
                        ),
                        IconButton(
                          onPressed: () async{
                            await player.seekToPrevious();
                          },
                          icon: Icon(Icons.skip_previous, size: 50),
                        ),
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              player.playing;
                            });
                            player.playing
                                ? await player.pause()
                                : await player.play();
                          },
                          icon: Icon(
                            player.playing ? Icons.pause : Icons.play_arrow,
                            size: 50,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await player.seekToNext();
                          },
                          icon: Icon(Icons.skip_next, size: 50),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.loop, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
