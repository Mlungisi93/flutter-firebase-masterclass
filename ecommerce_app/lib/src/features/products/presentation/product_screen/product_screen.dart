import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:ecommerce_app/src/common_widgets/async_value_widget.dart';
import 'package:ecommerce_app/src/features/cart/presentation/add_to_cart/add_to_cart_widget.dart';
import 'package:ecommerce_app/src/features/products/data/products_repository.dart';
import 'package:ecommerce_app/src/features/products/presentation/home_app_bar/home_app_bar.dart';
import 'package:ecommerce_app/src/features/products/presentation/product_screen/leave_review_action.dart';
import 'package:ecommerce_app/src/features/products/presentation/product_screen/product_average_rating.dart';
import 'package:ecommerce_app/src/features/reviews/presentation/product_reviews/product_reviews_list.dart';
import 'package:ecommerce_app/src/localization/string_hardcoded.dart';
import 'package:ecommerce_app/src/common_widgets/empty_placeholder_widget.dart';
import 'package:ecommerce_app/src/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/src/common_widgets/custom_image.dart';
import 'package:ecommerce_app/src/common_widgets/responsive_center.dart';
import 'package:ecommerce_app/src/common_widgets/responsive_two_column_layout.dart';
import 'package:ecommerce_app/src/constants/app_sizes.dart';
import 'package:ecommerce_app/src/features/products/domain/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the product page for a given product ID.
class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.productId});
  final ProductID productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: Consumer(
        builder: (context, ref, _) {
          final productValue = ref.watch(productStreamProvider(productId));
          return AsyncValueWidget<Product?>(
            value: productValue,
            data: (product) => product == null
                ? EmptyPlaceholderWidget(
                    message: 'Product not found'.hardcoded,
                  )
                : CustomScrollView(
                    slivers: [
                      ResponsiveSliverCenter(
                        padding: const EdgeInsets.all(Sizes.p16),
                        child: ProductDetails(product: product),
                      ),
                      ProductReviewsList(productId: productId),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// Shows all the product details along with actions to:
/// - leave a review
/// - add to cart
class ProductDetails extends ConsumerStatefulWidget {
  const ProductDetails({super.key, required this.product});
  final Product product;

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends ConsumerState<ProductDetails> {
  int _current = 0;
  final CarouselSliderController _mainCarouselController =
      CarouselSliderController();
  final CarouselSliderController _modalCarouselController =
      CarouselSliderController();
  final ScrollController _thumbnailScrollController = ScrollController();

  void _scrollThumbnails(bool forward) {
    if (forward) {
      _thumbnailScrollController.animateTo(
        _thumbnailScrollController.offset + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _thumbnailScrollController.animateTo(
        _thumbnailScrollController.offset - 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showImageModal(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              CarouselSlider.builder(
                itemCount: widget.product.imageUrls.length,
                itemBuilder: (BuildContext context, int index, int realIndex) {
                  return PhotoView(
                    imageProvider:
                        NetworkImage(widget.product.imageUrls[index]),
                    backgroundDecoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                options: CarouselOptions(
                  initialPage: index,
                  height: MediaQuery.of(context).size.height * 0.8,
                  enlargeCenterPage: true,
                  autoPlay: false,
                  aspectRatio: 16 / 9,
                  enableInfiniteScroll: false,
                ),
                carouselController: _modalCarouselController,
              ),
              Positioned(
                top: 0,
                right: -10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _modalCarouselController.previousPage(),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () => _modalCarouselController.nextPage(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatted =
        ref.watch(currencyFormatterProvider).format(widget.product.price);
    return ResponsiveTwoColumnLayout(
      startContent: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            children: [
              Stack(
                children: [
                  CarouselSlider.builder(
                    itemCount: widget.product.imageUrls.length,
                    itemBuilder:
                        (BuildContext context, int index, int realIndex) {
                      return GestureDetector(
                        onTap: () => _showImageModal(index),
                        child: SizedBox(
                          width: double.infinity,
                          height: 400,
                          child: PhotoView(
                            imageProvider:
                                NetworkImage(widget.product.imageUrls[index]),
                            backgroundDecoration: BoxDecoration(
                              color: Theme.of(context).canvasColor,
                            ),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 400,
                      enlargeCenterPage: true,
                      autoPlay: false,
                      aspectRatio: 16 / 9,
                      enableInfiniteScroll: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _current = index;
                        });
                      },
                    ),
                    carouselController: _mainCarouselController,
                  ),
                  Positioned(
                    left: 8.0,
                    top: 0.0,
                    bottom: 0.0,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: Colors.white.withOpacity(0.7)),
                      onPressed: () => _mainCarouselController.previousPage(),
                    ),
                  ),
                  Positioned(
                    right: 8.0,
                    top: 0.0,
                    bottom: 0.0,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.7)),
                      onPressed: () => _mainCarouselController.nextPage(),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 80,
                // Wrap ListView.builder in SingleChildScrollView with Row
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _thumbnailScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(widget.product.imageUrls.length,
                            (index) {
                          return InkWell(
                            onTap: () =>
                                _mainCarouselController.animateToPage(index),
                            child: Container(
                              width: 60.0,
                              height: 60.0,
                              margin: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _current == index
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  widget.product.imageUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () => _scrollThumbnails(false),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () => _scrollThumbnails(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      spacing: Sizes.p16,
      endContent: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.product.title,
                  style: Theme.of(context).textTheme.titleLarge),
              gapH8,
              Text(widget.product.description),
              // Only show average if there is at least one rating
              if (widget.product.numRatings >= 1) ...[
                gapH8,
                ProductAverageRating(product: widget.product),
              ],
              gapH8,
              const Divider(),
              gapH8,
              Text(priceFormatted,
                  style: Theme.of(context).textTheme.headlineSmall),
              gapH8,
              LeaveReviewAction(productId: widget.product.id),
              const Divider(),
              gapH8,
              AddToCartWidget(product: widget.product),
            ],
          ),
        ),
      ),
    );
  }
}
