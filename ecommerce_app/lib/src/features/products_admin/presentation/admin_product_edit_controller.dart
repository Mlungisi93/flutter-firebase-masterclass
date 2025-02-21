import 'dart:io';

import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/application/image_upload_service.dart';
import 'package:ecommerce_app/src/features/products_admin/data/image_upload_repository.dart';
import 'package:ecommerce_app/src/routing/app_router.dart';
import 'package:ecommerce_app/src/utils/notifier_mounted.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_product_edit_controller.g.dart';

@riverpod
class AdminProductEditController extends _$AdminProductEditController
    with NotifierMounted {
  @override
  FutureOr<void> build() {
    ref.onDispose(setUnmounted);
    // no-op
  }

  Future<bool> updateProduct({
    required Product product,
    required String title,
    required String description,
    required String price,
    required String availableQuantity,
    List<File> images = const [],
  }) async {
    final productsRepository = ref.read(productsRepositoryProvider);
    // Parse the input values (already pre-validated)
    final priceValue = double.parse(price);
    final availableQuantityValue = int.parse(availableQuantity);
    // Update product metadata (keep the pre-existing id and imageUrl)

    var updatedProduct = product.copyWith(
      title: title,
      description: description,
      price: priceValue,
      availableQuantity: availableQuantityValue,
    );

    if (images.isNotEmpty) {
      final downloadUrls = await ref
          .read(imageUploadRepositoryProvider)
          .uploadMultipleProductImage(product, images);
      List<String> updatedImageUrls = [];
      for (var imageUrl in product.imageUrls) {
        updatedImageUrls.add(imageUrl);
      }
      for (var imageUrl in downloadUrls) {
        updatedImageUrls.add(imageUrl);
      }
      updatedProduct = product.copyWith(
        imageUrls: updatedImageUrls,
        title: title,
        description: description,
        price: priceValue,
        availableQuantity: availableQuantityValue,
      );
    }

    state = const AsyncLoading();
    final value = await AsyncValue.guard(
        () => productsRepository.updateProduct(updatedProduct));
    final success = value.hasError == false;
    if (mounted) {
      state = value;
      if (success) {
        // on success, go back to previous screen
        ref.read(goRouterProvider).pop();
      }
    }
    return success;
  }

  Future<void> deleteProduct(Product product) async {
    final imageUploadService = ref.read(imageUploadServiceProvider);
    state = const AsyncLoading();
    final value =
        await AsyncValue.guard(() => imageUploadService.deleteProduct(product));
    final success = value.hasError == false;
    if (mounted) {
      state = value;
      if (success) {
        // on success, go back to previous screen
        ref.read(goRouterProvider).pop();
      }
    }
  }

  //delete product image
  Future<bool> deleteProductImage(Product product, String imageUrl) async {
    final imageUploadService = ref.read(imageUploadServiceProvider);
    state = const AsyncLoading();
    final value = await AsyncValue.guard(
        () => imageUploadService.deleteProductImage(product, imageUrl));
    final success = value.hasError == false;
    if (mounted) {
      state = value;
    }
    return success;
  }
}
