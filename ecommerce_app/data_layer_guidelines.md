# Data Layer Guidelines

## Directory Structure

```
lib/
  └── src/
      └── features/
          └── feature_name/
              └── data/
                  ├── repositories/
                  │   ├── fake_feature_repository.dart
                  │   └── firebase_feature_repository.dart
                  ├── models/
                  │   └── feature_dto.dart
                  └── test_data/
                      └── test_features.dart
```

## Data Layer Components

### Data Transfer Objects (DTOs)

1. DTO Classes:
   - Use `freezed` for immutability
   - Include JSON serialization
   - Map to/from domain models
   - Include proper validation
   - Document field mappings

2. DTO Methods:
   - Include fromDomain/toDomain
   - Handle null safety
   - Validate data conversion
   - Document field transformations
   - Include proper error handling

### Repositories

1. Repository Implementations:
   - Implement domain interfaces
   - Handle data source specifics
   - Include proper error handling
   - Handle offline scenarios
   - Document implementation details

2. Testing Implementations:
   - Create fake repositories
   - Use test data constants
   - Simulate network delays
   - Simulate error cases
   - Document test scenarios

## Naming Conventions

### Files

1. Repository files:
   - Prefix with data source (`firebase_`, `fake_`)
   - End with `_repository.dart`
   - Use snake_case
   - Be descriptive

2. DTO files:
   - End with `_dto.dart`
   - Use snake_case
   - Match domain model names

3. Test data files:
   - Prefix with `test_`
   - Use snake_case
   - Describe data purpose

### Classes

1. Repository classes:
   - Prefix with data source (`Firebase`, `Fake`)
   - End with 'Repository'
   - Match file names

2. DTO classes:
   - End with 'DTO'
   - Use PascalCase
   - Match domain model names

## Code Organization

1. Repositories:
   - One implementation per file
   - Clear error handling
   - Proper logging
   - Include unit tests

2. DTOs:
   - Keep conversion logic simple
   - Include serialization tests
   - Document field mappings
   - Handle edge cases

## Best Practices

1. Error Handling:
   - Map platform errors
   - Include error context
   - Handle network issues
   - Document error types

2. Testing:
   - Test all CRUD operations
   - Test error scenarios
   - Test offline behavior
   - Use proper test data

3. Firebase Best Practices:
   - Use proper security rules
   - Handle offline persistence
   - Batch related updates
   - Monitor query performance

## Code Examples

### DTO Implementation

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/product.dart';

part 'product_dto.freezed.dart';
part 'product_dto.g.dart';

@freezed
class ProductDTO with _$ProductDTO {
  const factory ProductDTO({
    required String id,
    required String title,
    required double price,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'available_quantity') required int availableQuantity,
    String? description,
  }) = _ProductDTO;

  factory ProductDTO.fromJson(Map<String, dynamic> json) =>
      _$ProductDTOFromJson(json);

  factory ProductDTO.fromDomain(Product product) {
    return ProductDTO(
      id: product.id,
      title: product.title,
      price: product.price,
      imageUrl: product.imageUrl,
      availableQuantity: product.availableQuantity,
      description: product.description,
    );
  }

  const ProductDTO._();

  Product toDomain() {
    return Product(
      id: id,
      title: title,
      price: price,
      imageUrl: imageUrl,
      availableQuantity: availableQuantity,
      description: description,
    );
  }
}
```

### Firebase Repository Implementation

```dart
class FirebaseProductRepository implements ProductRepositoryInterface {
  FirebaseProductRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _service = FirebaseFirestore.instance.collection('products');

  @override
  Stream<AsyncValue<List<Product>>> watchProducts() {
    try {
      return _service.snapshots().map((snapshot) {
        return AsyncValue.data(
          snapshot.docs
              .map((doc) => ProductDTO.fromJson(doc.data()).toDomain())
              .toList(),
        );
      });
    } catch (e, st) {
      return Stream.value(AsyncValue.error(e, st));
    }
  }

  @override
  Future<AsyncValue<Product>> getProduct(String id) async {
    try {
      final doc = await _service.doc(id).get();
      final dto = ProductDTO.fromJson(doc.data()!);
      return AsyncValue.data(dto.toDomain());
    } catch (e, st) {
      return AsyncValue.error(e, st);
    }
  }

  @override
  Future<AsyncValue<void>> updateProduct(Product product) async {
    try {
      final dto = ProductDTO.fromDomain(product);
      await _service.doc(product.id).update(dto.toJson());
      return const AsyncValue.data(null);
    } catch (e, st) {
      return AsyncValue.error(e, st);
    }
  }
}
```

### Test Implementation

```dart
class FakeProductRepository implements ProductRepositoryInterface {
  FakeProductRepository([List<Product>? initialProducts])
      : _products = initialProducts ?? testProducts;

  final List<Product> _products;
  
  static const _delay = Duration(milliseconds: 500);

  @override
  Stream<AsyncValue<List<Product>>> watchProducts() async* {
    await Future.delayed(_delay);
    yield AsyncValue.data(_products);
  }

  @override
  Future<AsyncValue<Product>> getProduct(String id) async {
    await Future.delayed(_delay);
    try {
      final product = _products.firstWhere((p) => p.id == id);
      return AsyncValue.data(product);
    } catch (e, st) {
      return AsyncValue.error(e, st);
    }
  }

  @override
  Future<AsyncValue<void>> updateProduct(Product product) async {
    await Future.delayed(_delay);
    try {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        return const AsyncValue.data(null);
      }
      throw Exception('Product not found');
    } catch (e, st) {
      return AsyncValue.error(e, st);
    }
  }
}
```

### Test Data

```dart
final testProducts = [
  Product(
    id: '1',
    title: 'Test Product 1',
    price: 9.99,
    imageUrl: 'assets/products/test1.jpg',
    availableQuantity: 10,
  ),
  Product(
    id: '2',
    title: 'Test Product 2',
    price: 19.99,
    imageUrl: 'assets/products/test2.jpg',
    availableQuantity: 5,
  ),
];
```

## Testing Guidelines

1. DTO Tests:
   - Test JSON serialization
   - Test domain conversion
   - Test field validation
   - Test edge cases

```dart
void main() {
  group('ProductDTO', () {
    test('fromJson/toJson work properly', () {
      final json = {
        'id': '1',
        'title': 'Test Product',
        'price': 9.99,
        'image_url': 'test.jpg',
        'available_quantity': 10,
      };
      
      final dto = ProductDTO.fromJson(json);
      expect(dto.toJson(), json);
    });

    test('fromDomain/toDomain work properly', () {
      final product = Product(
        id: '1',
        title: 'Test Product',
        price: 9.99,
        imageUrl: 'test.jpg',
        availableQuantity: 10,
      );
      
      final dto = ProductDTO.fromDomain(product);
      final converted = dto.toDomain();
      expect(converted, equals(product));
    });
  });
}
```

2. Repository Tests:
   - Test CRUD operations
   - Test stream behavior
   - Test error handling
   - Test offline scenarios

```dart
void main() {
  group('FirebaseProductRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseProductRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseProductRepository(fakeFirestore);
    });

    test('watchProducts emits products on changes', () async {
      final product = testProducts.first;
      await fakeFirestore
          .collection('products')
          .doc(product.id)
          .set(ProductDTO.fromDomain(product).toJson());

      expect(
        repository.watchProducts(),
        emits(predicate<AsyncValue<List<Product>>>((value) {
          return value.hasValue &&
              value.value!.length == 1 &&
              value.value!.first == product;
        })),
      );
    });
  });
}
```

3. Integration Tests:
   - Test repository chains
   - Test caching behavior
   - Test error recovery
   - Test offline sync

```dart
void main() {
  group('Product Repository Integration', () {
    testWidgets('handles offline/online transitions', (tester) async {
      // Test implementation
    });
  });
}
