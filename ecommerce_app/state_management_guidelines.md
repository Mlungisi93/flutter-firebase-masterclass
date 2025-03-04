# State Management Guidelines (Riverpod)

## Directory Structure

Each feature follows this structure:

```
lib/src/features/feature_name/
  ├── application/        # Business logic & services
  │   └── feature_service.dart
  ├── data/              # Repositories & data sources
  │   ├── local/         # Local data sources
  │   └── remote/        # Remote data sources
  ├── domain/            # Models & entities
  └── presentation/      # UI components & controllers
```

## State Management Conventions

### Service Class Structure

1. Services must:
   - Use Riverpod code generation (`@riverpod`)
   - Handle business logic for the feature
   - Accept `Ref` for dependency injection
   - Use repository pattern for data access

Example:
```dart
@riverpod
class CartService {
  CartService(this.ref);
  final Ref ref;

  // Dependencies
  Repository get repository => ref.read(repositoryProvider);

  // Methods
  Future<void> performAction() async {
    // Implementation
  }
}
```

### Provider Conventions

1. Use code generation with `@riverpod`:
   ```dart
   @riverpod
   Stream<Data> dataStream(Ref ref) {
     return ref.watch(repositoryProvider).watchData();
   }
   ```

2. For simple state:
   ```dart
   @riverpod
   class QueryNotifier extends _$QueryNotifier {
     @override
     String build() => '';
   
     void updateQuery(String query) => state = query;
   }
   ```

### Naming Conventions

1. Files:
   - Service: `feature_service.dart`
   - Repository: `feature_repository.dart`
   - Models: `feature.dart`

2. Classes & Providers:
   - Service: `FeatureService`
   - Repository: `FeatureRepository`
   - Providers: descriptive names like `cartItemsCount`

## Repository Pattern

1. Repository Structure:
```dart
@riverpod
abstract class Repository {
  // Watch data (reactive)
  Stream<Data> watchData();
  
  // Fetch data (one-time)
  Future<Data> fetchData();
  
  // Modify data
  Future<void> setData(Data data);
}
```

## Error Handling

1. Use AsyncValue for handling async states:
```dart
ref.watch(dataProvider).when(
  data: (data) => // UI for data,
  error: (error, stack) => // Error UI,
  loading: () => // Loading UI,
);
```

## Best Practices

### 1. State Management
- Use `@riverpod` for code generation
- Leverage `ref.watch()` for reactive state
- Keep services focused and single-purpose
- Use repositories for data access
- Handle loading and error states consistently

### 2. Dependency Injection
- Use `ref.read()` for dependencies
- Use `ref.watch()` for reactive state
- Avoid service locator pattern
- Keep dependencies explicit

### 3. Testing
- Mock dependencies using Riverpod's testing utilities
- Test providers independently
- Verify state transitions
- Test error scenarios

### 4. Code Organization
- Group related providers in the same file
- Use part files for generated code
- Keep UI components separate from business logic
- Follow consistent file naming

## Code Examples

### 1. Simple Provider
```dart
@riverpod
Future<List<Product>> productsSearchResults(Ref ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  return ref.watch(productsListSearchProvider(searchQuery).future);
}
```

### 2. Service Class
```dart
@riverpod
class CartService {
  CartService(this.ref);
  final Ref ref;

  AuthRepository get authRepository => ref.read(authRepositoryProvider);
  
  Future<void> addItem(Item item) async {
    final cart = await _fetchCart();
    final updated = cart.addItem(item);
    await _setCart(updated);
  }
}
```

### 3. Reactive UI
```dart
@riverpod
Stream<Cart> cart(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user != null) {
    return ref.watch(remoteCartRepositoryProvider).watchCart(user.uid);
  } else {
    return ref.watch(localCartRepositoryProvider).watchCart();
  }
}
```

## Performance Considerations

1. State Updates:
   - Use select() for granular rebuilds
   - Avoid unnecessary state changes
   - Cache expensive computations

2. Provider Organization:
   - Break down large providers
   - Use family modifiers for parameterized providers
   - Keep providers scoped appropriately
