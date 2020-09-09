import 'package:event_app/providers/user.dart';
import 'package:flutter/foundation.dart';

class Product with ChangeNotifier {
  final int id;
  final String title;
  final String body;
  final String image;
  final User user;

  Product({
    @required this.id,
    @required this.title,
    @required this.body,
    this.image,
    this.user
  });
}
