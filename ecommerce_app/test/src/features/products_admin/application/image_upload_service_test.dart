import 'package:ecommerce_app/src/features/products_admin/application/image_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/data/image_upload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockImageUploadRepository extends Mock implements ImageUploadRepository {}

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  group('ImageUploadService', () {
    late MockImageUploadRepository mockImageUploadRepository;
    late MockProductsRepository mockProductsRepository;

    setUp(() {
      mockImageUploadRepository = MockImageUploadRepository();
      mockProductsRepository = MockProductsRepository();
    });

    ImageUploadService makeImageUploadService() {
      final container = ProviderContainer(
        overrides: [
          imageUploadRepositoryProvider
              .overrideWithValue(mockImageUploadRepository),
          productsRepositoryProvider.overrideWithValue(mockProductsRepository),
        ],
      );
      addTearDown(container.dispose);
      return container.read(imageUploadServiceProvider);
    }

    test('uploadProduct calls uploadProductImageFromAsset and createProduct',
        () async {
      // Arrange
      final product = Product(
          id: 'id',
          imageUrl: 'imageUrl',
          title: '',
          description: '',
          price: 0,
          availableQuantity: 0);
      final downloadUrl = 'downloadUrl';
      when(() => mockImageUploadRepository.uploadProductImageFromAsset(
          product.imageUrl, product.id)).thenAnswer((_) async => downloadUrl);
      when(() => mockProductsRepository.createProduct(product.id, downloadUrl))
          .thenAnswer((_) => Future.value()); //(_) async => {}

      final imageUploadService = makeImageUploadService();

      // Act
      await imageUploadService.uploadProduct(product);

      // Assert
      verify(() => mockImageUploadRepository.uploadProductImageFromAsset(
          product.imageUrl, product.id)).called(1);
      verify(() =>
              mockProductsRepository.createProduct(product.id, downloadUrl))
          .called(1);
    });

    test('uploadProduct throws error if uploadProductImageFromAsset fails',
        () async {
      // Arrange
      final product = Product(
          id: 'id',
          imageUrl: 'imageUrl',
          title: '',
          description: '',
          price: 0,
          availableQuantity: 0);
      when(() => mockImageUploadRepository.uploadProductImageFromAsset(
              product.imageUrl, product.id))
          .thenThrow(Exception('Connection failed'));

      final imageUploadService = makeImageUploadService();
      // Act and Assert
      expect(() => imageUploadService.uploadProduct(product),
          throwsA(isA<Exception>()));
      verifyNever(() => mockProductsRepository.createProduct(product.id, ''));
    });

    test('uploadProduct throws error if createProduct fails', () async {
      // Arrange
      final product = Product(
          id: 'id',
          imageUrl: 'imageUrl',
          title: '',
          description: '',
          price: 0,
          availableQuantity: 0);
      final downloadUrl = 'downloadUrl';
      when(() => mockImageUploadRepository.uploadProductImageFromAsset(
          product.imageUrl, product.id)).thenAnswer((_) async => downloadUrl);
      when(() => mockProductsRepository.createProduct(product.id, downloadUrl))
          .thenThrow(Exception('Mock error'));

      final imageUploadService = makeImageUploadService();

      // Act and Assert

      expect(() => imageUploadService.uploadProduct(product),
          throwsA(isA<Exception>()));
      verify(() => mockImageUploadRepository.uploadProductImageFromAsset(
          product.imageUrl, product.id)).called(1);
    });
  });
}
