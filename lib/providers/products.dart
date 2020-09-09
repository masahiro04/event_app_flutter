import 'dart:convert';
import 'package:event_app/providers/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final String authToken;
  final int userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get myItems {
    if (userId == null) {
      return [];
    }
    return [..._items.where((prodItem) => prodItem.user.id == userId)];
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<Map<String, String>> getAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return {};
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;

    return {
      'Content-Type': 'application/json',
      'access-token': extractedUserData['access-token'],
      'client': extractedUserData['client'],
      'uid': extractedUserData['uid']
    };
  }

  Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;

    return extractedUserData['user_id'];
  }

  Future<void> fetchAndSetProducts() async {
    var url = 'http://10.0.2.2:3001/api/events';
    var headers = await getAuthorization();

    try {
      final response = await http.get(url, headers: headers);
      final extractedData = json.decode(response.body)['response'] as List;

      if (extractedData == null) {
        return;
      }

      final List<Product> loadedProducts = [];
      for (int i = 0; i < extractedData.length; i++) {
        loadedProducts.add(Product(
          id: extractedData[i]['id'].toString(),
          title: extractedData[i]['title'],
          description: extractedData[i]['body'],
          price: 10,
          user: User(extractedData[i]['user']['id'], extractedData[i]['user']['name']),
          imageUrl: 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
        ));
      }
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {throw (error);
    }
  }

  Future<void> addProduct(Product product) async {
    final url = 'http://10.0.2.2:3001/api/events';
    try {
      final headers = await getAuthorization();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'title': product.title,
          'body': product.description,
          'imageUrl': 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
          'price': 10,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final headers = await getAuthorization();
      final url = 'http://10.0.2.2:3001/api/events/$id';
      await http.patch(url,
          headers: headers,
          body: json.encode({
            'title': newProduct.title,
            'body': newProduct.description,
            'imageUrl': 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
            'price': newProduct.price
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final headers = await getAuthorization();
    final url ='http://10.0.2.2:3001/api/events/$id';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
