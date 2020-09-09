import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../screens/product_detail_screen.dart';
import '../providers/product.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    return Card(
      child: Column(
        children: [
          ListTile(
              onTap: () {
                Navigator.of(context).pushNamed(
                  ProductDetailScreen.routeName,
                  arguments: product.id,
                );
              },
              title: Text(product.title,
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                DateFormat('yyyy/MM/dd').format(product.createdAt),
                style: TextStyle(color: Colors.grey),
              ),
              leading: Image.network(
                product.image,
                fit: BoxFit.cover,
                width: 70,
                height: 70,
              )),
        ],
      ),
    );
  }
}
