import 'models.dart';

class PulseboardStats {
  const PulseboardStats({
    required this.userCount,
    required this.postCount,
    required this.completedTaskCount,
    required this.taskCount,
  });

  final int userCount;
  final int postCount;
  final int completedTaskCount;
  final int taskCount;

  int get completionPercentage => taskCount == 0
      ? 0
      : (completedTaskCount * 100 / taskCount).round();

  factory PulseboardStats.fromData({
    required List<User> users,
    required List<Post> posts,
    required List<Todo> todos,
  }) {
    return PulseboardStats(
      userCount: users.length,
      postCount: posts.length,
      completedTaskCount: todos.where((todo) => todo.completed).length,
      taskCount: todos.length,
    );
  }
}

List<Todo> filterTodos(List<Todo> todos, {bool? completed}) {
  if (completed == null) return List<Todo>.unmodifiable(todos);
  return List<Todo>.unmodifiable(
    todos.where((todo) => todo.completed == completed),
  );
}
