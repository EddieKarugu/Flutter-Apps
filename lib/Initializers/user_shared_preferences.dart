import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  static SharedPreferences? _preferences; // Make it private

  // Getter to safely access preferences, ensuring initialization
  static SharedPreferences get prefs {
    if (_preferences == null) {
      throw Exception("SharedPreferences not initialized. Call init() first.");
    }
    return _preferences!;
  }

  // Initialization method
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
}