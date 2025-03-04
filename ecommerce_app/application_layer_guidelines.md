# Application Layer Guidelines

## Directory Structure

```
lib/
  └── src/
      └── features/
          └── feature_name/
              └── application/
                  ├── providers/
                  │   └── feature_providers.dart
                  └── controllers/
                      └── feature_controller.dart
```

## Application Layer Components

### Controllers

1. Controller Classes:
   - Use StateNotifier for complex state
   - Use AsyncNotifier for async operations
   - Follow single responsibility principle
   - Handle proper error management
   - Use proper state immutability

2. Controller Methods:
   - Return AsyncValue for operations
   - Handle loading states
   - Proper error propagation
   - Document side effects
   - Keep methods focused

### Providers

1. Provider Definitions:
   - Use proper provider types
   - Define clear dependencies
   - Follow proper scoping rules
   - Include documentation
   - Handle proper overrides for testing

2. Provider Organization:
   - Group related providers
   - Use proper provider families
   - Handle auto-disposal
   - Define clear dependencies
   - Handle caching properly

## Naming Conventions

### Files

1. Controller files:
   - End with `_controller.dart`
   - Use snake_case
   - Describe controller purpose

2. Provider files:
   - End with `_providers.dart`
   - Use snake_case
   - Group related providers

### Classes

1. Controller classes:
   - Use PascalCase
   - End with 'Controller'
   - Match file names
   - Include state type in name

2. Provider variables:
   - Use camelCase
   - End with 'Provider'
   - Be descriptive of purpose
   - Include provider type in name

## Code Organization

1. Controllers:
   - One controller per file
   - Clear state management
   - Proper error handling
   - Include unit tests

2. Providers:
   - Group by feature
   - Clear dependencies
   - Proper scoping
   - Include documentation

## Best Practices

1. State Management:
   - Use immutable state
   - Handle all state cases
   - Clear state transitions
   - Document state changes

2. Error Handling:
   - Use AsyncValue for results
   - Include error messages
   - Handle edge cases
   - Provide recovery mechanisms

3. Testing:
   - Mock dependencies
   - Test state transitions
   - Test error scenarios
   - Test side effects

## Code Examples

### State Definition

```dart
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default({}) Map<String, int> items,
    @Default(0.0) double totalPrice,
    @Default(false) bool isLoading,
    String? error,
  }) = _CartState;
}
```

### Controller Implementation

```dart
class CartController extends StateNotifier<CartState> {
  CartController({
    required this.productRepository,
    required this.checkoutService,
  }) : super(const CartState());

  final ProductRepositoryInterface productRepository;
  final CheckoutService checkoutService;

  Future<void> addToCart(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final product = await productRepository.getProduct(productId);
      final currentQuantity = state.items[productId] ?? 0;
      
      state = state.copyWith(
        items: {
          ...state.items,
          productId: currentQuantity + 1,
        },
        isLoading: false,
      );
      _updateTotalPrice();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add item to cart: $e',
      );
    }
  }

  Future<AsyncValue<void>> checkout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await checkoutService.processCheckout(state.items);
      state = const CartState(); // Reset cart after successful checkout
      return const AsyncValue.data(null);
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: 'Checkout failed: $e',
      );
      return AsyncValue.error(e, st);
    }
  }

  void _updateTotalPrice() async {
    double total = 0.0;
    for (final entry in state.items.entries) {
      final product = await productRepository.getProduct(entry.key);
      total += product.price * entry.value;
    }
    state = state.copyWith(totalPrice: total);
  }
}
```

### Provider Definitions

```dart
// State provider for simple values
final darkModeProvider = StateProvider<bool>((ref) => false);

// Provider for repository instances
final productRepositoryProvider = Provider<ProductRepositoryInterface>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ProductRepository(firestore);
});

// StateNotifierProvider for complex state
final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(
    productRepository: ref.watch(productRepositoryProvider),
    checkoutService: ref.watch(checkoutServiceProvider),
  );
});

// AsyncNotifierProvider for async operations
final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(productRepositoryProvider);
    return await repository.fetchProducts();
  }
}

// Provider family for parameterized providers
final productProvider =
    FutureProvider.family<Product, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProduct(productId);
});
```

## Testing Guidelines

1. Controller Tests:
   - Test state transitions
   - Test async operations
   - Test error handling
   - Mock dependencies

```dart
void main() {
  group('CartController', () {
    late MockProductRepository mockRepository;
    late MockCheckoutService mockCheckoutService;
    late CartController controller;

    setUp(() {
      mockRepository = MockProductRepository();
      mockCheckoutService = MockCheckoutService();
      controller = CartController(
        productRepository: mockRepository,
        checkoutService: mockCheckoutService,
      );
    });

    test('addToCart updates state correctly', () async {
      final product = Product(
        id: '1',
        title: 'Test Product',
        price: 9.99,
        imageUrl: 'test.jpg',
        availableQuantity: 10,
      );

      when(() => mockRepository.getProduct('1'))
          .thenAnswer((_) async => product);

      await controller.addToCart('1');

      expect(controller.state.items['1'], equals(1));
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
    });
  });
}
```

2. Provider Tests:
   - Test provider behavior
   - Test provider dependencies
   - Test state updates
   - Test disposal behavior

```dart
void main() {
  group('Cart Providers', () {
    test('cartControllerProvider initializes with empty state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartState = container.read(cartControllerProvider);
      
      expect(cartState.items, isEmpty);
      expect(cartState.totalPrice, equals(0.0));
      expect(cartState.isLoading, isFalse);
      expect(cartState.error, isNull);
    });
  });
}
```

3. Integration Tests:
   - Test provider chains
   - Test complex workflows
   - Test error propagation
   - Test state persistence

```dart
void main() {
  group('Checkout Flow', () {
    testWidgets('complete checkout process works', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test implementation
    });
  });
}
