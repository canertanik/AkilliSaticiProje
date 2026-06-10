import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double getSubtotal(bool isLoggedIn) => _items.fold(0, (sum, item) => sum + item.getLineTotal(isLoggedIn));

  void add(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _items.add(CartItem(product: product, quantity: 1));
    } else {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + 1);
    }
    notifyListeners();
  }

  void decrease(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    final current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
