import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryIconWidget extends StatelessWidget {
  final CategoryModel category;
  final double size;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          category.icon,
          color: category.color,
          size: size * 0.52,
        ),
      ),
    );
  }
}
