import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:perez_advmobprog/screens/details_screen.dart';
import '../widgets/custom_text.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }
  // Gets all products from the ProductService and updates the state accordingly.
  Future<void> _fetchProducts() async {
    try {
      final products = await ProductService().getAllProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  // Filters the products based on the search query entered by the user.
  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.title.toLowerCase().contains(query);
      }).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: CustomText(
          text: 'Error: $_error',
          fontSize: 14.sp,
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: CustomText(
          text: _searchController.text.isEmpty
              ? 'No products found.'
              : 'No results for "${_searchController.text}"',
          fontSize: 14.sp,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(product: product),
              ),
            );
          },
          child: Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'product-image-${product.id}',
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image, size: 24.sp),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: product.title,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}