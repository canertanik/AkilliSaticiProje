import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void add(Product product) {
    final idx = _items.indexWhere((c) => c.product.id == product.id);
    if (idx != -1) {
      _items[idx].quantity += 1;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((c) => c.product.id == product.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double get total {
    return _items.fold(0.0, (s, c) => s + c.totalPrice);
  }
}
