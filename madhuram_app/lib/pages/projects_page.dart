import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiClient.getProjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        if (result['success'] != true) {
          return Center(child: Text((result['error'] ?? 'Failed to load projects').toString()));
        }
        final data = result['data'];
        final projects = (data is List) ? data : <dynamic>[];
        if (projects.isEmpty) {
          return const Center(child: Text('No projects found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = projects[index] as Map<String, dynamic>;
            final name = (p['project_name'] ?? p['name'] ?? '').toString();
            final client = (p['client_name'] ?? p['client'] ?? '').toString();
            final location = (p['location'] ?? '').toString();
            return Card(
              child: ListTile(
                title: Text(name.isEmpty ? 'Unnamed Project' : name),
                subtitle: Text([client, location].where((e) => e.isNotEmpty).join(' • ')),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}
