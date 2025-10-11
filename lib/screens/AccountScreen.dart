import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phanplay/Initializers/user_shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class Accountscreen extends StatefulWidget {
  const Accountscreen({super.key});

  @override
  State<Accountscreen> createState() => _AccountscreenState();
}

class _AccountscreenState extends State<Accountscreen> {
  String? accountImage = UserSharedPrefs.prefs.getString(
    'PhanPlayAccountImage',
  );
  File? imagePath;

  void getAccountImage() {
    if (accountImage != null && accountImage!.isNotEmpty) {
      setState(() {
        imagePath = File(accountImage!);
      });
    }
  }

  @override
  void initState(){
    super.initState();
    getAccountImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: CircleAvatar(
                    backgroundImage: imagePath != null
                        ? FileImage(imagePath!)
                        : AssetImage('assets/images/phanplay.png'),
                    backgroundColor: Colors.deepPurple,
                    radius: 40,
                  ),
                ),
                IconButton(onPressed: (){
                  selectAccountImage();
                }, icon: Icon(Icons.edit_note))
              ],
            ),
            Text('NewUser', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> selectAccountImage() async {
    final selectedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      accountImage = selectedImage?.path;
    });
    await UserSharedPrefs.prefs.setString(
      'PhanPlayAccountImage',
      selectedImage!.path,
    );
    getAccountImage();
  }
}
