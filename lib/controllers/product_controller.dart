import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductController with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.get('/products');
      if (response.statusCode == 200) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          data = response.data['data'];
        }
        _products = data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } on DioException catch (e) {
      _errorMessage = e.message;
      print("Error fetching products: $_errorMessage");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createProduct(Product product) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post(
        '/products',
        data: product.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchProducts();
        return true;
      }
      return false;
    } on DioException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(int id, Product product) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.put(
        '/products/$id',
        data: product.toJson(),
      );
      if (response.statusCode == 200) {
        await fetchProducts();
        return true;
      }
      return false;
    } on DioException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(int id) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.delete('/products/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchProducts();
        return true;
      }
      return false;
    } on DioException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
