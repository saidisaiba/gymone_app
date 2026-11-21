import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({Key? key}) : super(key: key);

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  bool _isLoading = true;
  bool _isCheckingOut = false;
  List<dynamic> _products = [];
  final List<dynamic> _cart = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService.get('products');
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> parsedList = [];
        if (decoded is List) {
          parsedList = decoded;
        } else if (decoded is Map) {
          if (decoded['products'] is List) {
            parsedList = decoded['products'];
          } else if (decoded['data'] is List) {
            parsedList = decoded['data'];
          }
        }

        setState(() {
          _products = parsedList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load products (Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name'] ?? 'Product'} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitCheckout() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Calculate total amount
      double total = 0;
      List<int> productIds = [];
      for (var item in _cart) {
        total += double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        if (item['id'] != null) {
          productIds.add(int.tryParse(item['id'].toString()) ?? 0);
        }
      }

      // Send order/invoice to backend database
      final response = await ApiService.post('invoices', {
        'items': productIds,
        'total': total,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context); // Close cart sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed and saved to invoices successfully!'),
          ),
        );
        setState(() {
          _cart.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit order (Code: ${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting order: $e')));
    } finally {
      setState(() {
        _isCheckingOut = false;
      });
    }
  }

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double total = 0;
        for (var item in _cart) {
          total += double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shopping Cart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (_cart.isEmpty)
                const Expanded(
                  child: Center(child: Text('Your cart is empty.')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'Item'),
                        trailing: Text('\$${item['price'] ?? '0.00'}'),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_cart.isEmpty || _isCheckingOut)
                      ? null
                      : _submitCheckout,
                  child: _isCheckingOut
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Checkout & Save Invoice'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Shop & Products'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _showCartDialog,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _products.isEmpty
          ? const Center(child: Text('No products available.'))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag,
                          color: Colors.blue,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product['description'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${product['price'] ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _addToCart(product),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
