import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  static SharedPreferences? prefs;

  static Future init () async{
    prefs = await SharedPreferences.getInstance();
  }
}