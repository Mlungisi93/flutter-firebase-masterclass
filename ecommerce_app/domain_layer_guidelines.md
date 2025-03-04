# Domain Layer Guidelines

## Directory Structure

```
lib/
  └── src/
      └── features/
          └── feature_name/
              └── domain/
                  ├── repositories/
                  │   └── i_feature_repository.dart
                  └── models/
                      └── feature.dart
```

## Domain Layer Conventions

### Model Structure

1. Models must:
   - Be immutable using freezed
   - Have proper type definitions
   - Include proper validation
   - Use non-nullable types where possible
   - Include proper documentation

2. Model Properties:
   - All fields must be final
   - Use appropriate types (no dynamic)
   - Document field purpose
   - Include validation when needed

### Interface Structure

1. Repository Interfaces must:
   - Define clear contract for implementations
   - Be prefixed with 'I'
   - Include method documentation
   - Return AsyncValue for error handling
   - Handle offline scenarios

2. Repository Methods:
   - Use Stream for real-time data
   - Use Future for one-time operations
   - Return AsyncValue for proper error handling
   - Document all error scenarios

## Naming Conventions

### Files

1. Model files:
   - No suffix needed
   - Use snake_case
   - Be descriptive of content
   - Group in models directory

2. Interface files:
   - Use `i_` prefix
   - End with `_repository.dart`
   - Use snake_case
   - Group in repositories directory

### Classes

1. Model classes:
   - Use PascalCase
   - No suffix needed
   - Match their file names

2. Interface classes:
   - Use PascalCase
   - Start with 'I'
   - End with 'Repository'
   - Match their file names

## Code Organization

1. Models:
   - One model per file
   - Group related models together
   - Include proper documentation
   - Include validation logic

2. Interfaces:
   - One interface per file
   - Define clear method contracts
   - Include error handling
   - Document all methods

## Best Practices

1. Domain Models:
   - Keep models focused and specific
   - Use proper value types
   - Include validation logic where needed
   - Use copyWith for immutability

2. Interfaces:
   - Define clear method contracts
   - Use AsyncValue for error handling
   - Keep methods focused
   - Document error scenarios

## Testing Guidelines

1. Directory Structure:
   ```
   test/
     └── src/
         └── features/
             └── feature_name/
                 └── domain/
                     ├── models/
                     │   └── feature_test.dart
                     └── repositories/
                         └── fake_feature_repository_test.dart
   ```

2. Model Testing:
   - Test constructor validations
   - Test copyWith functionality
   - Test equality comparisons
   - Test JSON serialization

3. Testing Conventions:
   - Group tests logically
   - Test success cases (AsyncValue.data)
   - Test failure cases (AsyncValue.error)
   - Test loading states (AsyncValue.loading)

## Code Example

### Domain Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    required double price,
    required String imageUrl,
    required int availableQuantity,
    String? description,
  }) = _Product;

  const Product._();

  // Validation
  bool get isAvailable => availableQuantity > 0;
  
  // Business logic
  double calculateTotalPrice(int quantity) {
    if (quantity <= 0) throw ArgumentError('Quantity must be positive');
    if (quantity > availableQuantity) {
      throw ArgumentError('Not enough stock available');
    }
    return price * quantity;
  }
}
```

### Repository Interface

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IProductRepository {
  /// Watches products in real-time.
  /// 
  /// Returns [AsyncValue.loading] initially, then:
  /// - [AsyncValue.data] with list of products on success
  /// - [AsyncValue.error] with error details on failure
  Stream<AsyncValue<List<Product>>> watchProducts();

  /// Fetches a single product by ID.
  /// 
  /// Returns:
  /// - [AsyncValue.data] with product on success
  /// - [AsyncValue.error] if product not found or other error occurs
  Future<AsyncValue<Product>> getProduct(String id);

  /// Updates an existing product.
  /// 
  /// Returns:
  /// - [AsyncValue.data] with null on success
  /// - [AsyncValue.error] if update fails or product doesn't exist
  Future<AsyncValue<void>> updateProduct(Product product);

  /// Watches a single product's availability in real-time.
  /// 
  /// Returns [AsyncValue.loading] initially, then:
  /// - [AsyncValue.data] with updated quantity
  /// - [AsyncValue.error] if product not found or other error
  Stream<AsyncValue<int>> watchProductAvailability(String id);
}
```

### Testing Examples

```dart
void main() {
  group('Product', () {
    test('isAvailable returns true when quantity > 0', () {
      final product = Product(
        id: '1',
        title: 'Test Product',
        price: 9.99,
        imageUrl: 'test.jpg',
        availableQuantity: 10,
      );
      expect(product.isAvailable, true);
    });

    test('calculateTotalPrice handles invalid quantity', () {
      final product = Product(
        id: '1',
        title: 'Test Product',
        price: 9.99,
        imageUrl: 'test.jpg',
        availableQuantity: 5,
      );
      expect(
        () => product.calculateTotalPrice(10),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
