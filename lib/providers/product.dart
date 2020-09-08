import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    this.price = 10,
    this.imageUrl = 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
  });
}
