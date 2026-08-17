import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart'; 

class CartService {
  // Future method to get the cart for a specific user by their user ID
  Future<List<Cart>> getCartByUserId(int userId) async {
    //Make a get request to the API to fetch the cart for specific user
    final response = await http.get(Uri.parse('$host/cart/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cart');
    }
  }


 Future<Cart> addProductToCart(int cartId, int productId, int quantity) async {
  // The endpoint for updating a specific cart.
  final uri = Uri.parse('$host/carts/$cartId');
  final headers = {'Content-Type': 'application/json'};

 // The body of the request, which includes the product ID and quantity to be added to the cart.
 // Merge means if the product exists in the cart, we can update the quantity instead
  final body = json.encode({
    'merge': true,
    'products': [
      {
        'id': productId,
        'quantity': quantity,
      },
    ]
  });
  final response = await http.put(uri, headers: headers, body: body);

  if (response.statusCode == 200) {
  
    return Cart.fromJson(json.decode(response.body));
  } else {
    
    throw Exception('Failed to add product to cart');
  }
}
}