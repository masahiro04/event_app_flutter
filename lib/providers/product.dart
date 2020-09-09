import 'dart:convert';
import 'package:event_app/providers/user.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final int id;
  final String title;
  final String body;
  final double price;
  final String image;
  final User user;

  Product({
    @required this.id,
    @required this.title,
    @required this.body,
    this.price = 10,
    this.image = 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    this.user
  });
}
