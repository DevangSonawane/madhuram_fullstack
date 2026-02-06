// Project Reducer - Handles project state changes
import 'package:redux/redux.dart';
import 'app_state.dart';
import 'project_actions.dart';

final Reducer<ProjectState> projectReducer = combineReducers<ProjectState>([
  TypedReducer<ProjectState, FetchProjectsStart>(_onFetchProjectsStart),
  TypedReducer<ProjectState, FetchProjectsSuccess>(_onFetchProjectsSuccess),
  TypedReducer<ProjectState, FetchProjectsFailure>(_onFetchProjectsFailure),
  TypedReducer<ProjectState, SelectProject>(_onSelectProject),
  TypedReducer<ProjectState, ClearSelectedProject>(_onClearSelectedProject),
  TypedReducer<ProjectState, CreateProjectStart>(_onCreateProjectStart),
  TypedReducer<ProjectState, CreateProjectSuccess>(_onCreateProjectSuccess),
  TypedReducer<ProjectState, CreateProjectFailure>(_onCreateProjectFailure),
  TypedReducer<ProjectState, UpdateProjectSuccess>(_onUpdateProjectSuccess),
  TypedReducer<ProjectState, DeleteProjectSuccess>(_onDeleteProjectSuccess),
]);

ProjectState _onFetchProjectsStart(ProjectState state, FetchProjectsStart action) {
  return state.copyWith(loading: true, error: null);
}

ProjectState _onFetchProjectsSuccess(ProjectState state, FetchProjectsSuccess action) {
  return state.copyWith(
    projects: action.projects,
    loading: false,
    error: null,
  );
}

ProjectState _onFetchProjectsFailure(ProjectState state, FetchProjectsFailure action) {
  return state.copyWith(
    loading: false,
    error: action.error,
  );
}

ProjectState _onSelectProject(ProjectState state, SelectProject action) {
  return state.copyWith(selectedProject: action.project);
}

ProjectState _onClearSelectedProject(ProjectState state, ClearSelectedProject action) {
  return state.copyWith(clearSelectedProject: true);
}

ProjectState _onCreateProjectStart(ProjectState state, CreateProjectStart action) {
  return state.copyWith(loading: true, error: null);
}

ProjectState _onCreateProjectSuccess(ProjectState state, CreateProjectSuccess action) {
  final updatedProjects = [...state.projects, action.project];
  return state.copyWith(
    projects: updatedProjects,
    loading: false,
    error: null,
  );
}

ProjectState _onCreateProjectFailure(ProjectState state, CreateProjectFailure action) {
  return state.copyWith(
    loading: false,
    error: action.error,
  );
}

ProjectState _onUpdateProjectSuccess(ProjectState state, UpdateProjectSuccess action) {
  final projectId = action.project['id']?.toString() ?? action.project['project_id']?.toString();
  final updatedProjects = state.projects.map((p) {
    final pId = p['id']?.toString() ?? p['project_id']?.toString();
    if (pId == projectId) {
      return action.project;
    }
    return p;
  }).toList();
  
  // Update selected project if it's the one being updated
  Map<String, dynamic>? updatedSelectedProject = state.selectedProject;
  if (state.selectedProjectId == projectId) {
    updatedSelectedProject = action.project;
  }
  
  return state.copyWith(
    projects: updatedProjects,
    selectedProject: updatedSelectedProject,
  );
}

ProjectState _onDeleteProjectSuccess(ProjectState state, DeleteProjectSuccess action) {
  final updatedProjects = state.projects.where((p) {
    final pId = p['id']?.toString() ?? p['project_id']?.toString();
    return pId != action.projectId;
  }).toList();
  
  // Clear selected project if it was deleted
  bool clearSelected = state.selectedProjectId == action.projectId;
  
  return state.copyWith(
    projects: updatedProjects,
    clearSelectedProject: clearSelected,
  );
}
