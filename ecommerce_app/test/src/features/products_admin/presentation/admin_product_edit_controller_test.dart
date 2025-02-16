import 'package:ecommerce_app/src/features/authentication/data/auth_repository.dart';
import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/presentation/admin_product_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../mocks.dart';

class MockRealProductsRepository extends Mock implements ProductsRepository {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  ProviderContainer makeProviderContainer(
      MockRealProductsRepository productsRepository,
      {MockGoRouter? goRouter}) {
    final container = ProviderContainer(
      overrides: goRouter == null
          ? [
              productsRepositoryProvider.overrideWithValue(productsRepository),
            ]
          : [
              productsRepositoryProvider.overrideWithValue(productsRepository),
              goRouterProvider.overrideWithValue(goRouter),
            ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUpAll(() {
    registerFallbackValue(Product(
        id: '',
        imageUrl: '',
        title: '',
        description: '',
        price: 0,
        availableQuantity: 0));
    registerFallbackValue(const AsyncLoading<int>());
  });

  group('AdminProductEditController', () {
    final product = Product(
      id: 'id',
      imageUrl: 'imageUrl',
      title: 'Test Product',
      description: 'Test Description',
      price: 100,
      availableQuantity: 10,
    );

    test('initial state is AsyncData', () {
      final productsRepository = MockRealProductsRepository();
      // create the ProviderContainer with the mock auth repository
      final container = makeProviderContainer(productsRepository);
      // create a listener
      final listener = Listener<AsyncValue<void>>();
      // listen to the provider and call [listener] whenever its value changes
      container.listen(
        adminProductEditControllerProvider,
        listener.call,
        fireImmediately: true,
      );
      // verify
      verify(
        // the build method returns a value immediately, so we expect AsyncData
        () => listener(null, const AsyncData<void>(null)),
      );
      // verify that the listener is no longer called
      verifyNoMoreInteractions(listener);
      // verify that [signInAnonymously] was not called during initialization
      verifyNever(() => productsRepository.updateProduct(product));
    });

    test('editProduct success', () async {
      final productsRepository = MockRealProductsRepository();
      // create the ProviderContainer with the mock auth repository
      when(() => productsRepository.updateProduct(product))
          .thenAnswer((_) => Future.value());
      final container = makeProviderContainer(productsRepository);
      // create a listener
      final listener = Listener<AsyncValue<void>>();
      // listen to the provider and call [listener] whenever its value changes
      container.listen(
        adminProductEditControllerProvider,
        listener.call,
        fireImmediately: true,
      );
      // sto
      const data = AsyncData<void>(null);
      // verify initial value from build method
      verify(() => listener(null, data));
      // run
      final controller =
          container.read(adminProductEditControllerProvider.notifier);

      await controller.updateProduct(
          product: product,
          title: '',
          description: '',
          price: "0",
          availableQuantity: "0");

      // verify
      verifyInOrder([
        // set loading state
        // * use a matcher since AsyncLoading != AsyncLoading with data
        () => listener(data, any(that: isA<AsyncLoading>())),
        // error when complete
        () => listener(
            any(that: isA<AsyncLoading>()), any(that: isA<AsyncError>())),
      ]);
      verifyNoMoreInteractions(listener);
      verify(() => productsRepository.updateProduct(any())).called(1);
    });

    test('editProduct failure', () async {
      final productsRepository = MockRealProductsRepository();

      when(() => productsRepository.updateProduct(product))
          .thenThrow(Exception('Update Failed'));

      final container = makeProviderContainer(productsRepository);
      // create a listener
      final listener = Listener<AsyncValue<void>>();
      // listen to the provider and call [listener] whenever its value changes
      container.listen(
        adminProductEditControllerProvider,
        listener.call,
        fireImmediately: true,
      );
      // sto
      const data = AsyncData<void>(null);
      // verify initial value from build method
      verify(() => listener(null, data));
      // run
      final controller =
          container.read(adminProductEditControllerProvider.notifier);
      await controller.updateProduct(
          product: product,
          title: '',
          description: '',
          price: "0",
          availableQuantity: "0");
      // verify
      verifyInOrder([
        // set loading state
        // * use a matcher since AsyncLoading != AsyncLoading with data
        () => listener(data, any(that: isA<AsyncLoading>())),
        // error when complete
        () => listener(
            any(that: isA<AsyncLoading>()), any(that: isA<AsyncError>())),
      ]);
      verifyNoMoreInteractions(listener);
      verify(() => productsRepository.updateProduct(any())).called(1);
    });
  });
}
