import '../domain/models.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final String id;
  final String name;
  final String username;
  final String email;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  User toDomain() => User(
        id: id,
        name: name,
        username: username,
        email: email,
      );
}

class PostDto {
  const PostDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final String id;
  final String userId;
  final String title;
  final String body;

  factory PostDto.fromJson(Map<String, dynamic> json) => PostDto(
        id: '${json['id']}',
        userId: '${json['user_id']}',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );

  Post toDomain() => Post(
        id: id,
        userId: userId,
        title: title,
        body: body,
      );
}

class TodoDto {
  const TodoDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  final String id;
  final String userId;
  final String title;
  final bool completed;

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
        id: '${json['id']}',
        userId: '${json['user_id']}',
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );

  Todo toDomain() => Todo(
        id: id,
        userId: userId,
        title: title,
        completed: completed,
      );
}
