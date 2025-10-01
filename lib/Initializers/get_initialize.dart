import 'package:get/get.dart';

import '../controllers/favourites_controller.dart';

class GetInitialize{
  static void init() {
    Get.put(FavouritesController());
  }
}