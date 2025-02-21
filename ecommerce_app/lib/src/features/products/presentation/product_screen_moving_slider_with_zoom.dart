// Card(
//         child: Padding(
//           padding: const EdgeInsets.all(Sizes.p16),
//           child: CarouselSlider.builder(
//             itemCount: product.imageUrls.length,
//             itemBuilder: (BuildContext context, int index, int realIndex) {
//               return SizedBox(
//                 width: double.infinity,
//                 height: 400,
//                 child: PhotoView(
//                   imageProvider: NetworkImage(product.imageUrls[index]),
//                   backgroundDecoration: BoxDecoration(
//                     color: Theme.of(context).canvasColor,
//                   ),
//                   minScale: PhotoViewComputedScale.contained,
//                   maxScale: PhotoViewComputedScale.covered * 2,
//                 ),
//               );
//             },
//             options: CarouselOptions(
//               height: 400,
//               enlargeCenterPage: true,
//               autoPlay: true,
//               aspectRatio: 16 / 9,
//               autoPlayCurve: Curves.fastOutSlowIn,
//               enableInfiniteScroll: true,
//               autoPlayAnimationDuration: Duration(milliseconds: 800),
//               viewportFraction: 0.8,
//             ),
//           ),
//         ),
//       )
