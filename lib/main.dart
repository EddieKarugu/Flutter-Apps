import 'package:flutter/material.dart';
import 'package:phanplay/Initializers/get_initialize.dart';
import 'package:phanplay/Initializers/user_shared_preferences.dart';
import 'package:phanplay/controllers/ThemeController.dart';
import 'package:phanplay/screens/botttom_nav_bar.dart';
import 'Initializers/musicPlayerService.dart';

void main() async{
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.phanplay.bg_demo.channel',
  //   androidNotificationChannelName: 'Audio playback',
  //   androidNotificationOngoing: true,
  // );
  WidgetsFlutterBinding.ensureInitialized();
  await UserSharedPrefs.init();
  MusicPlayerService.init();
  GetInitialize.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState(){
    super.initState();
    final getTheme = UserSharedPrefs.prefs!.getBool('PhanPlayIsLightMode') ?? true;

    ThemeController.isLightTheme.value = getTheme;
  }


  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
      valueListenable: ThemeController.isLightTheme,
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: value? ThemeData.light(useMaterial3: true)
              :ThemeData.dark(useMaterial3: true),
          home: BotttomNavBar(),
        );
      },
    );
  }
}
