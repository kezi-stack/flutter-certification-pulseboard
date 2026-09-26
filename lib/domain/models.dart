class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final String id;
  final String name;
  final String username;
  final String email;
}

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
}

class Todo {
  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  final String id;
  final String userId;
  final String title;
  final bool completed;
}

class DataResult<T> {
  const DataResult({required this.data, required this.fromCache});

  final T data;
  final bool fromCache;
}
