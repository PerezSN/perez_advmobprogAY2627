import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:perez_advmobprog/models/product.dart';
import 'package:perez_advmobprog/widgets/custom_text.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';





class DetailsScreen extends StatefulWidget {
  final Product product;

  const DetailsScreen({super.key, required this.product});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}



class _DetailsScreenState extends State<DetailsScreen> {
  int _currentImageIndex = 0;


//Method to add the product on the details screen to the cart
final CartService _cartService = CartService();
final ProductService _productService = ProductService();
void _addToCart() async {
 
  const int userId = 5;

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding to cart...')),
    );

    final List<Cart> userCarts = await _cartService.getCartByUserId(userId);

    if (userCarts.isNotEmpty) {
      final int cartId = userCarts.first.id;
      await _cartService.addProductToCart(cartId, widget.product.id, 1);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart!')),
      );
    } else {
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a cart for this user.')),
      );
    }
  } catch (e) {
   
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildProductDetails(),
          _buildReviews(),
        ],
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350.h,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.product.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageWidget = Image.network(
                  widget.product.images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                );
                // Only apply the Hero tag to the first image to avoid multiple heroes with the same tag.
                return index == 0
                    ? Hero(
                        tag: 'product-image-${widget.product.id}',
                        child: imageWidget)
                    : imageWidget;
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      List.generate(widget.product.images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      height: 8.h,
                      width: _currentImageIndex == index ? 24.w : 8.w,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CustomText(
                    text: widget.product.title,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                  ),
                ),
                CustomText(
                  text: '\$${widget.product.price.toStringAsFixed(2)}',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.star_rate_rounded, color: Colors.amber, size: 28.sp),
                SizedBox(width: 8.w),
                CustomText(
                  text: widget.product.rating.toStringAsFixed(1),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(width: 4.w),
                CustomText(
                  text: '(${widget.product.reviews.length} reviews)',
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
                const Spacer(),
                CustomText(
                  text: '${widget.product.stock} in stock',
                  fontSize: 14.sp,
                  color: widget.product.stock > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            CustomText(
              text: 'About this item',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: widget.product.description,
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
              height: 1.5,
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: widget.product.tags
                  .map((tag) => Chip(
                        label: CustomText(
                          text: tag,
                          fontSize: 12.sp,
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviews() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Reviews',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 16.h),
            widget.product.reviews.isEmpty
                ? Center(
                    child: CustomText(
                    text: 'No reviews yet.',
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.product.reviews.length,
                    itemBuilder: (context, index) {
                      final review = widget.product.reviews[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (starIndex) => Icon(
                                      starIndex < review.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 20.sp,
                                    ),
                                  ),
                                  const Spacer(),
                                  CustomText(
                                    text: review.reviewerName,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              CustomText(
                                text: review.comment,
                                fontSize: 13.sp,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h)
          .copyWith(bottom: 24.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.product.stock > 0
                  ? _addToCart
                  : null,
              icon: Icon(Icons.shopping_cart_checkout_rounded, size: 24.sp),
              label: const CustomText(
                text: 'Add to Cart',
                fontWeight: FontWeight.bold,
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
