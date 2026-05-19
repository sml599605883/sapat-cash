import 'product_detail_model.dart';

class ProductDetailCache {
  const ProductDetailCache._();

  static ProductDetailModel? _current;

  static ProductDetailModel? get current => _current;

  static void save(ProductDetailModel detail) {
    _current = detail;
  }

  static void clear() {
    _current = null;
  }
}
