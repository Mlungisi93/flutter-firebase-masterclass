import 'dart:io';
import 'dart:math';

import 'package:ecommerce_app/src/common_widgets/action_text_button.dart';
import 'package:ecommerce_app/src/common_widgets/alert_dialogs.dart';
import 'package:ecommerce_app/src/common_widgets/custom_image.dart';
import 'package:ecommerce_app/src/common_widgets/custom_text_button.dart';
import 'package:ecommerce_app/src/common_widgets/error_message_widget.dart';
import 'package:ecommerce_app/src/common_widgets/responsive_center.dart';
import 'package:ecommerce_app/src/common_widgets/responsive_two_column_layout.dart';
import 'package:ecommerce_app/src/constants/app_sizes.dart';
import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:ecommerce_app/src/features/products_admin/data/template_products_providers.dart';
import 'package:ecommerce_app/src/features/products_admin/presentation/admin_product_edit_controller.dart';
import 'package:ecommerce_app/src/features/products_admin/presentation/product_validator.dart';
import 'package:ecommerce_app/src/localization/string_hardcoded.dart';
import 'package:ecommerce_app/src/utils/async_value_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

Future<List<XFile>> pickImages() async {
  if (kIsWeb || Platform.isMacOS) {
    // Handle image picking for web and macOS
    final result = await ImagePicker().pickMultiImage();
    return result.map((file) => XFile(file.path)).toList();
    return [];
  } else {
    // Handle image picking for mobile
    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    return pickedFiles ?? [];
  }
}

/// Widget screen for updating existing products (edit mode).
/// Products are first created inside [AdminProductUploadScreen].
class AdminProductEditScreen extends ConsumerWidget {
  const AdminProductEditScreen({super.key, required this.productId});
  final ProductID productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // * By watching a [FutureProvider], the data is only loaded once.
    // * This prevents unintended rebuilds while the user is entering form data
    final productValue = ref.watch(productFutureProvider(productId));
    // * Using .when rather than [AsyncValueWidget] to provide custom error and
    // * loading screens
    return productValue.when(
      data: (product) => product != null
          ? AdminProductEditScreenContents(product: product)
          : Scaffold(
              appBar: AppBar(title: Text('Edit Product'.hardcoded)),
              body: Center(
                child: ErrorMessageWidget('Product not found'.hardcoded),
              ),
            ),
      // * to prevent a black screen, return a [Scaffold] from the error and
      // * loading screens
      error: (e, st) =>
          Scaffold(body: Center(child: ErrorMessageWidget(e.toString()))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// Widget containing most of the UI for editing a product
class AdminProductEditScreenContents extends ConsumerStatefulWidget {
  const AdminProductEditScreenContents({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<AdminProductEditScreenContents> createState() =>
      _AdminProductScreenContentsState();
}

class _AdminProductScreenContentsState
    extends ConsumerState<AdminProductEditScreenContents> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _availableQuantityController = TextEditingController();

  Product get product => widget.product;

  List<String> _existingImages = [];
  List<XFile> _newImages = [];
  int _currentExistingImageIndex = 0;
  int _currentNewImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize text fields with product data
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _availableQuantityController.text = product.availableQuantity.toString();
    _existingImages = List.from(product.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _availableQuantityController.dispose();
    super.dispose();
  }

  Future<void> _loadFromTemplate() async {
    final template = await ref.read(templateProductProvider(product.id).future);
    if (template != null) {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _priceController.text = template.price.toString();
      _availableQuantityController.text = template.availableQuantity.toString();
      _formKey.currentState!.validate();
    }
  }

  Future<void> _delete() async {
    final delete = await showAlertDialog(
      context: context,
      title: 'Are you sure?'.hardcoded,
      cancelActionText: 'Cancel'.hardcoded,
      defaultActionText: 'Delete'.hardcoded,
    );
    if (delete == true) {
      ref
          .read(adminProductEditControllerProvider.notifier)
          .deleteProduct(product);
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await pickImages();
    setState(() {
      _newImages = pickedFiles;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final images = _newImages.map((xfile) => File(xfile.path)).toList();
      final success = await ref
          .read(adminProductEditControllerProvider.notifier)
          .updateProduct(
            product: product,
            title: _titleController.text,
            description: _descriptionController.text,
            price: _priceController.text,
            availableQuantity: _availableQuantityController.text,
            images: images,
          );

      if (success) {
        // Inform the user that the product has been updated
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Product updated'.hardcoded,
            ),
          ),
        );
      }
    }
  }

  _removeExistingImage(String imageUrl) async {
    var delete = await showAlertDialog(
      context: context,
      title: 'Are you sure?'.hardcoded,
      content: 'Delete this image?'.hardcoded,
      cancelActionText: 'Cancel'.hardcoded,
      defaultActionText: 'Delete'.hardcoded,
    );

    if (delete == true) {
      var isSuccessful = false;
      isSuccessful = await ref
          .read(adminProductEditControllerProvider.notifier)
          .deleteProductImage(product, imageUrl);

      if (isSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image deleted'.hardcoded),
          ),
        );

        setState(() {
          _existingImages.remove(imageUrl);
          _currentExistingImageIndex = max(0, _currentExistingImageIndex - 1);
        });
      }
    }
  }

  void removeNewImage(XFile image) {
    setState(() {
      _newImages.remove(image);
      _currentNewImageIndex = max(0, _currentNewImageIndex - 1);
    });
  }

  void _nextExistingImage() {
    setState(() {
      _currentExistingImageIndex =
          (_currentExistingImageIndex + 1) % _existingImages.length;
    });
  }

  void _previousExistingImage() {
    setState(() {
      _currentExistingImageIndex =
          (_currentExistingImageIndex - 1 + _existingImages.length) %
              _existingImages.length;
    });
  }

  void _nextNewImage() {
    setState(() {
      _currentNewImageIndex = (_currentNewImageIndex + 1) % _newImages.length;
    });
  }

  void _previousNewImage() {
    setState(() {
      _currentNewImageIndex =
          (_currentNewImageIndex - 1 + _newImages.length) % _newImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      adminProductEditControllerProvider,
      (_, state) => state.showAlertDialogOnError(context),
    );
    final state = ref.watch(adminProductEditControllerProvider);
    final isLoading = state.isLoading;
    const autovalidateMode = AutovalidateMode.disabled;
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'.hardcoded),
        actions: [
          ActionTextButton(
            text: 'Save'.hardcoded,
            onPressed: isLoading ? null : _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Form(
            key: _formKey,
            child: ResponsiveTwoColumnLayout(
              startContent: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Column(
                    children: [
                      if (_existingImages.isNotEmpty) ...[
                        Text('Existing Images'.hardcoded),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              CustomImage(
                                  imageUrl: _existingImages[
                                      _currentExistingImageIndex]),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: isLoading
                                      ? CircularProgressIndicator()
                                      : Icon(Icons.delete),
                                  onPressed: isLoading
                                      ? null
                                      : () => _removeExistingImage(
                                          _existingImages[
                                              _currentExistingImageIndex]),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: _previousExistingImage,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  onPressed: _nextExistingImage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_newImages.isNotEmpty) ...[
                        Text('New Images'.hardcoded),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              kIsWeb
                                  ? Image.network(
                                      _newImages[_currentNewImageIndex].path)
                                  : Image.file(File(
                                      _newImages[_currentNewImageIndex].path)),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => removeNewImage(
                                      _newImages[_currentNewImageIndex]),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: _previousNewImage,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  onPressed: _nextNewImage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: _pickImages,
                        child: Text('Pick Images'),
                      ),
                    ],
                  ),
                ),
              ),
              spacing: Sizes.p16,
              endContent: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          label: Text('Title'.hardcoded),
                        ),
                        autovalidateMode: autovalidateMode,
                        validator:
                            ref.read(productValidatorProvider).titleValidator,
                      ),
                      gapH8,
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          label: Text('Description'.hardcoded),
                        ),
                        autovalidateMode: autovalidateMode,
                        validator: ref
                            .read(productValidatorProvider)
                            .descriptionValidator,
                      ),
                      gapH8,
                      TextFormField(
                        controller: _priceController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          label: Text('Price'.hardcoded),
                        ),
                        autovalidateMode: autovalidateMode,
                        validator:
                            ref.read(productValidatorProvider).priceValidator,
                      ),
                      gapH8,
                      TextFormField(
                        controller: _availableQuantityController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          label: Text('Available Quantity'.hardcoded),
                        ),
                        autovalidateMode: autovalidateMode,
                        validator: ref
                            .read(productValidatorProvider)
                            .availableQuantityValidator,
                      ),
                      gapH16,
                      const Divider(),
                      gapH8,
                      EditProductOptions(
                        onLoadFromTemplate:
                            isLoading ? null : _loadFromTemplate,
                        onDelete: isLoading ? null : _delete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive widget with options to preload product data and delete a product
class EditProductOptions extends StatelessWidget {
  const EditProductOptions(
      {super.key, required this.onLoadFromTemplate, required this.onDelete});
  final VoidCallback? onLoadFromTemplate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ResponsiveTwoColumnLayout(
      rowMainAxisAlignment: MainAxisAlignment.center,
      startContent: CustomTextButton(
        text: 'Load from Template'.hardcoded,
        style: Theme.of(context).textTheme.titleSmall,
        onPressed: onLoadFromTemplate,
      ),
      endContent: CustomTextButton(
        text: 'Delete Product'.hardcoded,
        style:
            Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red),
        onPressed: onDelete,
      ),
      spacing: Sizes.p8,
    );
  }
}
