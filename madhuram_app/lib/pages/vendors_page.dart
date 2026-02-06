import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final partners = [
      {
        'id': 'BP-001',
        'name': 'Acme Supplies Ltd',
        'type': 'Vendor',
        'contactPerson': 'Robert Fox',
        'email': 'robert@acme.com',
        'phone': '+1 234 567 890',
        'location': 'New York, USA',
        'status': 'Active',
        'rating': 4.8,
      },
      {
        'id': 'BP-002',
        'name': 'Global Tech Industries',
        'type': 'Vendor',
        'contactPerson': 'Sarah Connor',
        'email': 'sarah@globaltech.com',
        'phone': '+1 111 222 333',
        'location': 'San Francisco, USA',
        'status': 'Pending',
        'rating': 4.2,
      },
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: partners.length,
      itemBuilder: (context, index) {
        final p = partners[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.building2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Chip(label: Text((p['status'] as String))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.user),
                    const SizedBox(width: 6),
                    Text(p['contactPerson'] as String),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.mail),
                    const SizedBox(width: 6),
                    Text(p['email'] as String),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.phone),
                    const SizedBox(width: 6),
                    Text(p['phone'] as String),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.mapPin),
                    const SizedBox(width: 6),
                    Text(p['location'] as String),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
