import 'dart:convert';
import 'dart:io';
import 'package:event_app/providers/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path/path.dart';
import 'package:async/async.dart';

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
    return _items.where((prodItem) => prodItem.user.id == userId).toList();
  }

  Product findById(int id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<Map<String, String>> getAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return {};
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;

    return {
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
          id: extractedData[i]['id'],
          title: extractedData[i]['title'],
          body: extractedData[i]['body'],
          user: User(extractedData[i]['user']['id'], extractedData[i]['user']['name']),
          image: extractedData[i]['image'] == null ? 'http://10.0.2.2:3001/sample.png' : 'http://10.0.2.2:3001/${extractedData[i]['image']}',
          createdAt: DateTime.parse(extractedData[i]['created_at']),
        ));
      }
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {throw (error);
    }
  }

  Future<void> addProduct(Product product, File image) async {
    try {
      var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
      var url = Uri.parse('http://10.0.2.2:3001/api/events');
      var length = await image.length();

      final headers = await getAuthorization();
      var request = new http.MultipartRequest('POST', url);
      var multipartFile = new http.MultipartFile('event[image]', stream, length, filename: basename(image.path));

      request.files.add(multipartFile);
      request.fields.addAll( { 'event[title]': product.title, 'event[body]': product.body,});
      request.headers.addAll(headers);
      var response = await request.send();
      print(response.statusCode);
      print(response);
      print(response.request);

      Product newProduct;
      response.stream.transform(utf8.decoder).listen((value) {
        final pData = json.decode(value)['response'];
        newProduct = Product(
          title: pData['title'],
          body: pData['body'],
          image: pData['image'] == null ? 'http://10.0.2.2:3001/sample.png' : 'http://10.0.2.2:3001/${pData['image']}',
          id: pData['id'],
          user: User(pData['user']['id'], pData['user']['name']),
          createdAt: pData['created_at'],
        );
          print(pData);
        _items.add(newProduct);
        notifyListeners();
      });
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(int id, Product product, image) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
      var url = Uri.parse('http://10.0.2.2:3001/api/events/$id');
      var length = await image.length();

      final headers = await getAuthorization();
      var request = new http.MultipartRequest('PUT', url);
      var multipartFile = new http.MultipartFile('event[image]', stream, length, filename: basename(image.path));

      request.files.add(multipartFile);
      request.fields.addAll( { 'event[id]': product.id.toString() ,'event[title]': product.title, 'event[body]': product.body,});
      request.headers.addAll(headers);
      var response = await request.send();
      print(response.statusCode);
      print(response);
      print(response.request);
      response.stream.transform(utf8.decoder).listen((value) {
        final pData = json.decode(value)['response'];
        _items[prodIndex] =Product(
            title: pData['title'],
            body: pData['body'],
            image: pData['image'] == null ? 'http://10.0.2.2:3001/sample.png' : 'http://10.0.2.2:3001/${pData['image']}',
            id: pData['id'],
            user: User(pData['user']['id'], pData['user']['name']),
            createdAt: DateTime.parse(pData['created_at']),);
        notifyListeners();
      });
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(int id) async {
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
      throw HttpException('削除に失敗しました');
    }
    existingProduct = null;
  }
}
