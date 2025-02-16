import 'package:ecommerce_app/src/features/products_admin/presentation/admin_product_upload_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/application/image_upload_service.dart';
import 'package:ecommerce_app/src/routing/app_router.dart';
import 'package:ecommerce_app/src/utils/notifier_mounted.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

class MockImageUploadService extends Mock implements ImageUploadService {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockImageUploadService mockImageUploadService;
  late MockGoRouter mockGoRouter;
  late ProviderContainer container;

  setUp(() {
    mockImageUploadService = MockImageUploadService();
    mockGoRouter = MockGoRouter();
    container = ProviderContainer(
      overrides: [
        imageUploadServiceProvider.overrideWithValue(mockImageUploadService),
        goRouterProvider.overrideWithValue(mockGoRouter),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });
  setUpAll(() {
    registerFallbackValue(const AsyncLoading<int>());
  });

  group('AdminProductUploadController', () {
    final product = Product(
        id: 'id',
        imageUrl: 'imageUrl',
        title: '',
        description: '',
        price: 0,
        availableQuantity: 0);

    test('upload sets state to AsyncLoading', () async {
      // Arrange

      // Mock the uploadProduct method
      when(() => mockImageUploadService.uploadProduct(product))
          .thenAnswer((_) async {
        // Simulate a delay
        await Future.delayed(Duration.zero);

        // Return a future that completes
        return Future.value();
      });

      // Create the controller
      final controller =
          container.read(adminProductUploadControllerProvider.notifier);

      // Create a listener
      final listener = Listener<AsyncValue<void>>();

      // Listen to the provider
      container.listen(
        adminProductUploadControllerProvider,
        listener.call,
        fireImmediately: true,
      );

      // Initial state should be AsyncData with null value
      final initialData = AsyncData<void>(null);

      // Verify the initial state
      verify(() => listener(null, initialData));

      // Run the upload method
      await controller.upload(product);

      // Assert
      // Verify the state transitions
      // verifyInOrder([
      //   () => listener(initialData, any(that: isA<AsyncLoading>())),
      //   () => listener(any(that: isA<AsyncLoading>()), initialData),
      // ]);

      // Ensure the final state is AsyncLoading
      expect(
        container.read(adminProductUploadControllerProvider),
        isA<AsyncLoading>(),
      );
      verify(() => mockImageUploadService.uploadProduct(product)).called(1);
    });

    test('upload calls imageUploadService.uploadProduct', () async {
      // Arrange
      final controller =
          container.read(adminProductUploadControllerProvider.notifier);
      when(() => mockImageUploadService.uploadProduct(product))
          .thenAnswer((_) async => {});

      // Act
      await controller.upload(product);

      // Assert
      verify(() => mockImageUploadService.uploadProduct(product)).called(1);
    });

    test('upload navigates to admin edit product page on success', () async {
      // Arrange

      when(() => mockImageUploadService.uploadProduct(product))
          .thenAnswer((_) async => {});
      final controller =
          container.read(adminProductUploadControllerProvider.notifier);
      // Act
      await controller.upload(product);

      // Assert
      verify(() => mockGoRouter.goNamed(AppRoute.adminEditProduct.name,
          pathParameters: {'id': product.id})).called(1);
    });

    test('upload sets state to AsyncError on failure', () async {
      // Arrange
      final controller =
          container.read(adminProductUploadControllerProvider.notifier);
      when(() => mockImageUploadService.uploadProduct(product))
          .thenThrow(Exception('Mock error'));

      // Act
      await controller.upload(product);

      // Assert
      expect(controller.state, isA<AsyncError>());
    });

    test('upload does not set state to AsyncError if controller is unmounted',
        () async {
      // Arrange
      final controller =
          container.read(adminProductUploadControllerProvider.notifier);
      when(() => mockImageUploadService.uploadProduct(product))
          .thenThrow(Exception('Mock error'));

      // Act
      controller.setUnmounted();
      await controller.upload(product);

      // Assert
      expect(controller.state, isA<AsyncLoading>());
    });
  });
}
