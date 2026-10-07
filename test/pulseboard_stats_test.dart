import 'package:certificat/domain/models.dart';
import 'package:certificat/domain/pulseboard_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const users = [
    User(id: '1', name: 'Ada', username: 'ada', email: 'ada@example.org'),
    User(id: '2', name: 'Lin', username: 'lin', email: 'lin@example.org'),
  ];
  const posts = [
    Post(id: '1', userId: '1', title: 'One', body: 'First post'),
  ];

  test('calculates counts from the supplied domain records', () {
    final stats = PulseboardStats.fromData(
      users: users,
      posts: posts,
      todos: const [
        Todo(id: '1', userId: '1', title: 'Done', completed: true),
        Todo(id: '2', userId: '1', title: 'Open', completed: false),
        Todo(id: '3', userId: '2', title: 'Also done', completed: true),
      ],
    );

    expect(stats.userCount, 2);
    expect(stats.postCount, 1);
    expect(stats.completedTaskCount, 2);
    expect(stats.taskCount, 3);
  });

  test('rounds completion percentage to the nearest whole number', () {
    const stats = PulseboardStats(
      userCount: 0,
      postCount: 0,
      completedTaskCount: 2,
      taskCount: 3,
    );

    expect(stats.completionPercentage, 67);
  });

  test('returns zero progress when there are no tasks', () {
    const stats = PulseboardStats(
      userCount: 0,
      postCount: 0,
      completedTaskCount: 0,
      taskCount: 0,
    );

    expect(stats.completionPercentage, 0);
  });

  test('returns one hundred percent when every task is complete', () {
    const stats = PulseboardStats(
      userCount: 0,
      postCount: 0,
      completedTaskCount: 4,
      taskCount: 4,
    );

    expect(stats.completionPercentage, 100);
  });

  test('can filter to completed, open, or all tasks without mutating input', () {
    const tasks = [
      Todo(id: '1', userId: '1', title: 'Done', completed: true),
      Todo(id: '2', userId: '1', title: 'Open', completed: false),
    ];

    expect(filterTodos(tasks, completed: true).map((task) => task.id), ['1']);
    expect(filterTodos(tasks, completed: false).map((task) => task.id), ['2']);
    expect(filterTodos(tasks), hasLength(2));
    expect(() => filterTodos(tasks).add(tasks.first), throwsUnsupportedError);
    expect(tasks, hasLength(2));
  });
}
