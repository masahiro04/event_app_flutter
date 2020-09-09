import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _uid;
  int _userId;
  String _client;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
//    if (_expiryDate != null &&
//        _expiryDate.isAfter(DateTime.now()) &&
//        _token != null) {
//      return _token;
//    }
//    return null;
    if (_token != null) {
      return _token;
    }
    return null;
  }

  int get userId {
    return _userId;
  }

  Future<void> setAuthorizationData(http.Response response) async {
    final responseData = json.decode(response.body);
    final prefs = await SharedPreferences.getInstance();
    _token = response.headers['access-token'];
    _uid = response.headers['uid'];
    _client = response.headers['client'];
    _userId = responseData['data']['id'];
    final userData = json.encode(
      {
        'access-token': _token,
        'user_id': _userId,
        'uid': _uid,
        'client': _client,
      },
    );
    prefs.setString('userData', userData);
  }

  Future<void> _authenticate(String prefix, Map<String, String> body) async {
    final url = 'http://10.0.2.2:3001/api/auth$prefix';
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      _token = response.headers['access-token'];
      _uid = response.headers['uid'];
      _client = response.headers['client'];
      _userId = responseData['data']['id'];
      notifyListeners();
      setAuthorizationData(response);

//      final prefs = await SharedPreferences.getInstance();
//      final userData = json.encode(
//        {
//          'access-token': _token,
//          'user_id': _userId,
//          'uid': _uid,
//          'client': _client,
////          'expiryDate': _expiryDate.toIso8601String(),
//        },
//      );
//      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate('/',
      {
        'name': 'masahiro',
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<void> login(String email, String password) async {
    return _authenticate('/sign_in', {
      'email': email,
      'password': password,
    },);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
//    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

//    if (expiryDate.isBefore(DateTime.now())) {
//      return false;
//    }
    _token = extractedUserData['access-token'];
    _client = extractedUserData['client'];
    _uid = extractedUserData['uid'];
    _userId = extractedUserData['user_id'];
//    _expiryDate = expiryDate;
    notifyListeners();
//    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _uid = null;
    _client = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // prefs.remove('userData');
    prefs.clear();
  }

//  void _autoLogout() {
//    if (_authTimer != null) {
//      _authTimer.cancel();
//    }
//    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
//    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
//  }
}
