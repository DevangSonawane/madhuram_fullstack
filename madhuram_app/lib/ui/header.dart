import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, required this.title});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Icon(LucideIcons.package, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Madhuram Inventory',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1),
          const SizedBox(width: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      actions: [
        // Search field placeholder
        SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'Search…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        IconButton(icon: Icon(LucideIcons.bell), onPressed: () {}),
        const CircleAvatar(radius: 14, child: Text('ME')),
        const SizedBox(width: 8),
      ],
    );
  }
}
