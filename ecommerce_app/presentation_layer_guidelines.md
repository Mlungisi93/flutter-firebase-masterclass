# Presentation Layer Guidelines

## Directory Structure

```
lib/
  └── src/
      └── features/
          └── feature_name/
              └── presentation/
                  ├── feature_screen.dart
                  └── widgets/
                      └── feature_widget.dart
```

## Presentation Layer Conventions

### Screen Structure

1. Screens must:
   - Use Riverpod for state management
   - Follow single responsibility principle
   - Handle all UI states (loading, error, success)
   - Use proper layout constants from AppSpacing

2. Screen Properties:
   - Keep state in StateNotifier/StateProvider
   - Use proper widget keys for testing
   - Follow proper lifecycle management
   - Handle proper error display using AsyncValue

### Widget Structure

1. Widgets must:
   - Be focused on single responsibility
   - Use AppSpacing for all measurements
   - Follow proper widget lifecycle
   - Be properly documented
   - Use proper error boundaries

2. Widget Properties:
   - Use named parameters
   - Document required parameters
   - Use proper types with nullable safety
   - Follow immutability principles

## Naming Conventions

### Files

1. Screen files:
   - Use `_screen.dart` suffix
   - Use snake_case
   - Be descriptive of content

2. Widget files:
   - Use descriptive names without suffixes
   - Use snake_case
   - Describe widget purpose clearly

### Classes

1. Screen classes:
   - Use PascalCase
   - End with 'Screen'
   - Match their file names

2. Widget classes:
   - Use PascalCase
   - Use descriptive names
   - Match their file names

## Code Organization

1. Screens:
   - One screen per file
   - Include ProviderScope setup if needed
   - Handle AsyncValue states
   - Use proper error boundaries

2. Widgets:
   - Group related widgets in widgets folder
   - Keep widgets focused and small
   - Extract reusable components
   - Document widget purpose

## Best Practices

1. Layout:
   - Use AppSpacing for all measurements
   - Never use hard-coded values
   - Follow proper spacing guidelines
   - Use proper widget constraints

2. State Management:
   - Use Consumer for state consumption
   - Use ref.listen for side effects
   - Keep widgets pure
   - Handle all AsyncValue cases

3. Error Handling:
   - Show user-friendly error messages
   - Provide retry mechanisms
   - Handle edge cases
   - Use proper error boundaries

## Code Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/src/common_widgets/async_value_widget.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productValue = ref.watch(productProvider(productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: AsyncValueWidget(
        value: productValue,
        data: (product) => Padding(
          padding: EdgeInsets.all(AppSpacing.p16),
          child: ProductContent(product: product),
        ),
      ),
    );
  }
}

class ProductContent extends ConsumerWidget {
  const ProductContent({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.p16),
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: AppSpacing.p8),
        ProductImage(imageUrl: product.imageUrl),
        SizedBox(height: AppSpacing.p16),
        PriceWidget(price: product.price),
        SizedBox(height: AppSpacing.p24),
        AddToCartButton(product: product),
      ],
    );
  }
}

class AddToCartButton extends ConsumerWidget {
  const AddToCartButton({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryButton(
      onPressed: () {
        ref.read(cartControllerProvider.notifier).addToCart(product);
      },
      text: 'Add to Cart',
    );
  }
}
```

## Testing Guidelines

1. Widget Tests:
   - Test all UI states
   - Verify widget composition
   - Test user interactions
   - Mock dependencies using ProviderContainer

2. Golden Tests:
   - Create baseline screenshots
   - Test responsive layouts
   - Verify visual regressions
   - Document device configurations

3. Integration Tests:
   - Test complete user flows
   - Verify state management
   - Test error scenarios
   - Document test scenarios
