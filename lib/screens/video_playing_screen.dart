import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';

class VideoPlayingScreen extends StatefulWidget {
  const VideoPlayingScreen({super.key});

  @override
  State<VideoPlayingScreen> createState() => _VideoPlayingScreenState();
}

class _VideoPlayingScreenState extends State<VideoPlayingScreen> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState(){
    super.initState();
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, 'https://www.pexels.com/download/video/4568863/')
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        centerTitle: true,
      ),
      body: Center(
        child: BetterPlayer(controller: _betterPlayerController)
      )
    );
  }
}

