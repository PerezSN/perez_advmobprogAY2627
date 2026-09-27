import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:perez_advmobprog/models/cart.dart';
import 'package:perez_advmobprog/models/product.dart';
import 'package:perez_advmobprog/screens/details_screen.dart';
import 'package:perez_advmobprog/services/local_cart.dart';
import 'package:perez_advmobprog/services/product_service.dart';
import 'package:perez_advmobprog/widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final LocalCart _localCart = LocalCart();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    //listen to cart changes and rebuild the screen
    _localCart.cartNotifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _localCart.cartNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _navigateToDetails(BuildContext context, int productId) async {
    try {
      final Product product = await _productService.getProductById(productId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(product: product),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: CustomText(text: 'Failed to load product: $e')),
      );
    }
  }

  void _increaseQuantity(CartProduct product) {
    _localCart.increaseQuantity(product.id);
  }

  void _decreaseQuantity(CartProduct product) {
    _localCart.decreaseQuantity(product.id);
  }

  void _removeItem(CartProduct product) {
    _localCart.removeProduct(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: CustomText(text: '${product.title} removed from cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _localCart.items;

    return Scaffold(
      body: items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(items[index]);
                    },
                  ),
                ),
                _buildCartSummary(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100.sp, color: Colors.grey[300]),
          SizedBox(height: 20.h),
          CustomText(
            text: 'Your cart is empty',
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 10.h),
          CustomText(
            text: 'Add items from the product screen.',
            fontSize: 16.sp,
            color: Colors.grey,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProduct product) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context, product.id),
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        elevation: 3,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  product.thumbnail,
                  width: 90.w,
                  height: 90.h,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5.h),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, size: 22.sp),
                    onPressed: () => _increaseQuantity(product),
                  ),
                  CustomText(
                    text: product.quantity.toString(),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  IconButton(
                    icon: Icon(
                      product.quantity == 1
                          ? Icons.delete_outline
                          : Icons.remove_circle_outline,
                      size: 22.sp,
                      color: product.quantity == 1 ? Colors.redAccent : null,
                    ),
                    onPressed: () => product.quantity == 1
                        ? _removeItem(product)
                        : _decreaseQuantity(product),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    final subtotal = _localCart.subtotal;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h)
          .copyWith(bottom: 25.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                  text: 'Subtotal (${_localCart.totalItems} items)',
                  fontSize: 16.sp,
                  color: Colors.grey),
              CustomText(
                text: '\$${subtotal.toStringAsFixed(2)}',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                  text: 'Total', fontSize: 20.sp, fontWeight: FontWeight.bold),
              CustomText(
                text: '\$${subtotal.toStringAsFixed(2)}',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Checkout not implemented yet.')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                textStyle: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const CustomText(text: 'Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
