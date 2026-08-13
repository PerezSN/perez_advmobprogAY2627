import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product.dart';

// Service class to handle product-related operations, such as fetching products from the API.
class ProductService {
  //Future method to fetch all products from the API.
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products'));

   if (response.statusCode == 200){
    final Map<String, dynamic> data = json.decode(response.body);
    final List productsJson = data['products'] ?? [];
    return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
        throw Exception('Failed to load products');
   }
  }
}