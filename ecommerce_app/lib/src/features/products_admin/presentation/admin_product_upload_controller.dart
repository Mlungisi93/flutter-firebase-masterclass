import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/data/image_upload_repository.dart';
import 'package:ecommerce_app/src/routing/app_router.dart';
import 'package:ecommerce_app/src/utils/notifier_mounted.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_product_upload_controller.g.dart';

@riverpod
class AdminProductUploadController extends _$AdminProductUploadController
    with NotifierMounted {
  @override
  FutureOr<void> build() {
    ref.onDispose(setUnmounted);
    // no-op
  }

//But if you need to make two or more asynchronous calls that may use different repositories, consider doing so inside a separate service class that is completely independent from the UI (this can be more easily tested and can improve code reuse too):
  Future<void> upload(Product product) async {
    try {
      state = const AsyncLoading();
      final downloadUrl = await ref
          .read(imageUploadRepositoryProvider)
          .uploadProductImageFromAsset(product.imageUrl, product.id);
      // save downloadUrl to Firestore
      await ref
          .read(productsRepositoryProvider)
          .createProduct(product.id, downloadUrl);
      //we should not set the state if we are navigating on different page on success but we should do it on error instead
      // if (mounted) {
      //   state = const AsyncData(null);
      // }
      //on success, go to the edit product page
      ref.read(goRouterProvider).goNamed(AppRoute.adminEditProduct.name,
          pathParameters: {'id': product.id});
    } catch (e, st) {
      if (mounted) {
        state = AsyncError(e, st);
      }
    }
  }
}
