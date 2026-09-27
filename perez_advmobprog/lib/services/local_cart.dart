import '../models/cart.dart';
import 'package:flutter/foundation.dart';

//simple in-memory cart shared across screens
class LocalCart {
  //singleton instance
  static final LocalCart _instance = LocalCart._internal();
  factory LocalCart() => _instance;
  LocalCart._internal();

  final List<CartProduct> items = [];

  //notifier so CartScreen can listen and rebuild
  final ValueNotifier<int> cartNotifier = ValueNotifier(0);

  void addProduct(CartProduct product) {
    final existing = _findById(product.id);
    if (existing != null) {
      final index = items.indexOf(existing);
      items[index] = CartProduct(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: existing.quantity + 1,
        total: existing.price * (existing.quantity + 1),
        discountPercentage: existing.discountPercentage,
        discountedTotal: existing.discountedTotal,
        thumbnail: existing.thumbnail,
      );
    } else {
      items.add(product);
    }
    cartNotifier.value++;
  }

  void increaseQuantity(int productId) {
    final existing = _findById(productId);
    if (existing == null) return;
    final index = items.indexOf(existing);
    items[index] = CartProduct(
      id: existing.id,
      title: existing.title,
      price: existing.price,
      quantity: existing.quantity + 1,
      total: existing.price * (existing.quantity + 1),
      discountPercentage: existing.discountPercentage,
      discountedTotal: existing.discountedTotal,
      thumbnail: existing.thumbnail,
    );
    cartNotifier.value++;
  }

  void decreaseQuantity(int productId) {
    final existing = _findById(productId);
    if (existing == null) return;
    if (existing.quantity <= 1) {
      removeProduct(productId);
      return;
    }
    final index = items.indexOf(existing);
    items[index] = CartProduct(
      id: existing.id,
      title: existing.title,
      price: existing.price,
      quantity: existing.quantity - 1,
      total: existing.price * (existing.quantity - 1),
      discountPercentage: existing.discountPercentage,
      discountedTotal: existing.discountedTotal,
      thumbnail: existing.thumbnail,
    );
    cartNotifier.value++;
  }

  void removeProduct(int productId) {
    items.removeWhere((p) => p.id == productId);
    cartNotifier.value++;
  }

  void clear() {
    items.clear();
    cartNotifier.value++;
  }

  double get subtotal =>
      items.fold(0.0, (sum, p) => sum + p.price * p.quantity);

  int get totalItems => items.fold(0, (sum, p) => sum + p.quantity);

  CartProduct? _findById(int id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
