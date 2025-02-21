import 'dart:io';

import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/data/image_upload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_upload_service.g.dart';

class ImageUploadService {
  const ImageUploadService(this.ref);
  final Ref ref;

  Future<void> uploadProduct(Product product) async {
    // upload to storage and return download URL
    final downloadUrl = await ref
        .read(imageUploadRepositoryProvider)
        .uploadProductImageFromAsset(product.imageUrls[0], product.id);

    // write to Cloud Firestore
    await ref
        .read(productsRepositoryProvider)
        .createProduct(product.id, downloadUrl);
  }

  Future<void> deleteProduct(Product product) async {
    // delete images from storage and folder
    await ref.read(imageUploadRepositoryProvider).deleteProductImages(product);

    // delete product from Firestore
    await ref.read(productsRepositoryProvider).deleteProduct(product.id);
  }

  //delete image from storage and folder
  Future<void> deleteProductImage(Product product, String image) async {
    // delete image from storage
    await ref.read(imageUploadRepositoryProvider).deleteProductImage(image);

    // delete image from Firestore
    var updatedProduct = product.copyWith(
      imageUrls: product.imageUrls..remove(image),
    );
    await ref.read(productsRepositoryProvider).updateProduct(updatedProduct);
  }
}

@riverpod
ImageUploadService imageUploadService(Ref ref) {
  return ImageUploadService(ref);
}
