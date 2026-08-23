import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:perez_advmobprog/models/cart.dart';
import 'package:perez_advmobprog/models/product.dart';
import 'package:perez_advmobprog/screens/details_screen.dart';
import 'package:perez_advmobprog/services/cart_service.dart';
import 'package:perez_advmobprog/services/product_service.dart';
import 'package:perez_advmobprog/services/user_service.dart';
import 'package:perez_advmobprog/widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Cart>> _cartFuture;
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Assign _cartFuture synchronously so FutureBuilder never sees an
    // uninitialized late field on the first build.
    _cartFuture = _loadCart();
  }

  Future<List<Cart>> _loadCart() async {
    // Read the logged-in user's id from SharedPreferences then fetch their cart
    final userData = await UserService().getUserData();
    final userId = userData['id'] as int;
    return _cartService.getCartByUserId(userId);
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
        SnackBar(content: CustomText(text: 'Failed to load product details: $e')),
      );
    }
  }

 
  void _adjustQuantity(CartProduct product, int change) {
    
    setState(() {
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: CustomText(
              text: 'Quantity adjustment is a mock-up in this UI design.')),
    );
  }

  void _removeItem(CartProduct product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              CustomText(text: 'Remove item is a mock-up in this UI design.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Cart>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: CustomText(text: 'Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyCart();
          }

          final cart = snapshot.data!.first;
          final cartProducts = cart.products;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: cartProducts.length,
                  itemBuilder: (context, index) {
                    final cartProduct = cartProducts[index];
                    return _buildCartItem(cartProduct);
                  },
                ),
              ),
              _buildCartSummary(cart),
            ],
          );
        },
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
            text: 'Looks like you haven\'t added anything to your cart yet.',
            fontSize: 16.sp,
            color: Colors.grey,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: () {
              // This assumes the home screen can be controlled to switch tabs.
              // In this app setup, this is for demonstration.
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: CustomText(
              text: 'Start Shopping',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
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
                      text:
                          '\$${product.price.toStringAsFixed(2)}',
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
                    icon: Icon(Icons.remove_circle_outline, size: 22.sp),
                    onPressed: () => _adjustQuantity(product, -1),
                  ),
                  CustomText(
                    text: product.quantity.toString(),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, size: 22.sp),
                    onPressed: () => _adjustQuantity(product, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(Cart cart) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h).copyWith(bottom: 25.h),
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
                  text: 'Subtotal (${cart.totalProducts} items)',
                  fontSize: 16.sp,
                  color: Colors.grey),
              CustomText(
                text: '\$${cart.total.toStringAsFixed(2)}',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(text: 'Discount', fontSize: 16.sp, color: Colors.grey),
              CustomText(
                text:
                    '-\$${(cart.total - cart.discountedTotal).toStringAsFixed(2)}',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
                text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
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
                      content: Text(
                          'Checkout functionality is not implemented yet.')),
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
