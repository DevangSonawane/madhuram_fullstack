// Project Actions - Matching React ProjectContext actions

class FetchProjectsStart {}

class FetchProjectsSuccess {
  final List<Map<String, dynamic>> projects;
  FetchProjectsSuccess(this.projects);
}

class FetchProjectsFailure {
  final String error;
  FetchProjectsFailure(this.error);
}

class SelectProject {
  final Map<String, dynamic> project;
  SelectProject(this.project);
}

class ClearSelectedProject {}

class CreateProjectStart {}

class CreateProjectSuccess {
  final Map<String, dynamic> project;
  CreateProjectSuccess(this.project);
}

class CreateProjectFailure {
  final String error;
  CreateProjectFailure(this.error);
}

class UpdateProjectSuccess {
  final Map<String, dynamic> project;
  UpdateProjectSuccess(this.project);
}

class DeleteProjectSuccess {
  final String projectId;
  DeleteProjectSuccess(this.projectId);
}
