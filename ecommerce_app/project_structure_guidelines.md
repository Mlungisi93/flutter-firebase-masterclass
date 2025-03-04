# Flutter Project Structure and Naming Conventions

## Directory Structure

```
lib/
  ├── src/
  │   ├── constants/
  │   │   └── app_spacing.dart
  │   └── features/
  │       └── feature_name/
  │           ├── application/
  │           │   ├── providers/
  │           │   │   └── feature_providers.dart
  │           │   └── controllers/
  │           │       └── feature_controller.dart
  │           ├── domain/
  │           │   ├── models/
  │           │   │   └── feature.dart
  │           │   └── repositories/
  │           │       └── i_feature_repository.dart
  │           ├── data/
  │           │   ├── repositories/
  │           │   │   ├── firebase_feature_repository.dart
  │           │   │   └── fake_feature_repository.dart
  │           │   └── models/
  │           │       └── feature_dto.dart
  │           └── presentation/
  │               ├── feature_screen.dart
  │               └── widgets/
  │                   └── feature_widget.dart
```

## Naming Conventions

### Files and Directories

1. All file and directory names should use snake_case
2. Feature directories should be descriptive and domain-specific
3. Interface files should be prefixed with `i_` (e.g., `i_repository.dart`)
4. State management files should use the suffix matching their type:
   - Provider files: `_providers.dart`
   - Controller files: `_controller.dart`
5. Model files should have no suffix
6. Screen files should use the suffix `_screen.dart`
7. DTO files should use the suffix `_dto.dart`
8. Constant files should be named descriptively (e.g., `app_spacing.dart`)

### Classes

1. Use PascalCase for class names
2. Widget classes should match their file names in PascalCase
3. Interface classes should be prefixed with 'I'
4. Controller classes should be suffixed with 'Controller'
5. Repository classes should be prefixed with source (e.g., 'Firebase', 'Fake')
6. Spacing constants should use semantic naming (e.g., 'AppSpacing')

### Code Organization

1. Group related widgets in the same directory
2. Separate concerns into appropriate layers:
   - application: State management (Providers, Controllers)
   - domain: Models and repository interfaces
   - data: Repository implementations and DTOs
   - presentation: Screens and widgets
3. Common functionality and constants should reside in the src directory

### Layout Constants (AppSpacing)

1. All UI measurements must use predefined constants from AppSpacing:
   - Margins and padding (e.g., AppSpacing.p16, AppSpacing.p24)
   - Grid spacing (e.g., AppSpacing.p8)
   - Component spacing (e.g., AppSpacing.p4)
2. Never use hard-coded numeric values for:
   - Spacing and layout
   - Typography
   - Component dimensions
3. AppSpacing should follow a consistent scaling system:
   - Base unit multiplication (e.g., p4, p8, p16, p24)
   - Semantic naming for common use cases
4. All new layout-related constants should be added to AppSpacing for reusability

### Widget Structure

1. Main feature widgets should use ConsumerWidget when needing Riverpod state
2. Smaller, presentational components should use StatelessWidget
3. Each widget should be in its own file
4. Test-related widget components should be marked with @visibleForTesting

## Best Practices

1. Keep widget files focused on a single responsibility
2. Maintain a clear separation between presentation and business logic
3. Follow a consistent pattern for state management using Riverpod
4. Implement interfaces for repositories
5. All business logic should be testable and independent of UI

## Testing Guidelines

1. Directory Structure:
   ```
   test/
     └── src/
         └── features/
             └── feature_name/
                 ├── application/
                 │   └── controllers/
                 │       └── feature_controller_test.dart
                 ├── domain/
                 │   └── models/
                 │       └── feature_test.dart
                 ├── data/
                 │   ├── repositories/
                 │   │   └── firebase_feature_repository_test.dart
                 │   └── models/
                 │       └── feature_dto_test.dart
                 └── presentation/
                     ├── feature_screen_test.dart
                     └── widgets/
                         └── feature_widget_test.dart
   ```

2. Testing Requirements:
   - All business logic must have unit tests
   - All widgets must have widget tests
   - Mock all external dependencies
   - Test files should mirror source code structure

3. Testing Conventions:
   - Test files should end with `_test.dart`
   - Use meaningful test group and test case names
   - Each test should focus on a single behavior
   - Maintain test independence (no shared state)

4. Testability Guidelines:
   - Keep UI logic separate from business logic
   - Avoid static methods for testable code
   - Use repository interfaces for external services
   - Provide test keys for important UI elements

## Example Implementation

### Domain Model

```dart
// Product model in domain layer
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    required double price,
    required String imageUrl,
  }) = _Product;
}
```

### Repository Interface

```dart
// Repository interface in domain layer
abstract class IProductRepository {
  Stream<AsyncValue<List<Product>>> watchProducts();
  Future<AsyncValue<Product>> getProduct(String id);
}
```

### Controller

```dart
// Controller in application layer
class ProductController extends StateNotifier<AsyncValue<List<Product>>> {
  ProductController({
    required this.productRepository,
  }) : super(const AsyncValue.loading()) {
    _fetchProducts();
  }

  final IProductRepository productRepository;

  void _fetchProducts() {
    state = const AsyncValue.loading();
    productRepository.watchProducts().listen((products) {
      state = products;
    });
  }
}
```

### Screen

```dart
// Screen in presentation layer
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsValue = ref.watch(productsControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: AsyncValueWidget(
        value: productsValue,
        data: (products) => GridView.builder(
          padding: EdgeInsets.all(AppSpacing.p16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.p16,
            crossAxisSpacing: AppSpacing.p16,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
          ),
        ),
      ),
    );
  }
}
