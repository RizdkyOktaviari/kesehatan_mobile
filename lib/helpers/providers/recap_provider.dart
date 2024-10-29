import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/recap_model.dart';
import 'auth_provider.dart';

class RecapProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<RecapModel> _recaps = [];
  bool _isLoading = false;
  String? _error;

  RecapProvider(this.authProvider);

  List<RecapModel> get recaps => _recaps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecaps() async {
    if (!authProvider.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://108.137.67.23/api/all-daily-summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          final Map<String, dynamic> data = responseData['data'];
          _recaps = data.entries
              .map((entry) => RecapModel.fromJson(entry.key, entry.value))
              .toList();
        } else {
          _error = responseData['message']?.toString() ?? 'Unknown error occurred';
        }
      } else if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        await authProvider.logout();
      } else {
        _error = 'Failed to fetch recaps: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }
}