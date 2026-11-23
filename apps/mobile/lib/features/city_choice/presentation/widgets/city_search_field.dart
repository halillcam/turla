import 'package:flutter/material.dart';

import '../../../../core/constants/strings.dart';

class CitySearchField extends StatelessWidget {
  const CitySearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: AppStrings.citySearchHint,
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
