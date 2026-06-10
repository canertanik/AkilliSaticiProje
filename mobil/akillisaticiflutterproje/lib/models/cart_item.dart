import 'package:meta/meta.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice {
    final price = product.minPrice ?? product.maxPrice ?? 0.0;
    return price * quantity;
  }
}
