import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:schulcloud/app/app.dart';

import '../bloc.dart';
import '../data.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  CourseDetailScreen({@required this.course}) : assert(course != null);

  @override
  Widget build(BuildContext context) {
    return ProxyProvider2<NetworkService, UserService, Bloc>(
      builder: (_, network, user, __) => Bloc(network: network, user: user),
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(course.name, style: TextStyle(color: Colors.black)),
          backgroundColor: course.color,
        ),
        bottomNavigationBar: MyAppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () => _showCourseFiles(context, course),
            ),
          ],
        ),
        body: LessonList(course: course),
      ),
    );
  }
}

class LessonList extends StatelessWidget {
  final Course course;

  const LessonList({@required this.course}) : assert(course != null);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Lesson>>(
      stream: Provider.of<Bloc>(context).getLessonsOfCourse(course.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        var tiles = [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 12,
            ),
            child: Text(
              course.description,
              style: TextStyle(fontSize: 20),
            ),
          ),
          for (var lesson in snapshot.data)
            ListTile(
              title: Text(
                lesson.name,
                style: TextStyle(fontSize: 20),
              ),
              onTap: () => _pushLessonScreen(
                context: context,
                lesson: lesson,
                course: course,
              ),
            )
        ];

        return ListView.separated(
          itemCount: tiles.length,
          itemBuilder: (context, index) => tiles[index],
          separatorBuilder: (context, index) => Divider(),
        );
      },
    );
  }

  void _pushLessonScreen({BuildContext context, Lesson lesson, Course course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(course: course, lesson: lesson),
      ),
    );
  }
}

void _showCourseFiles(BuildContext context, Course course) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProxyProvider<NetworkService, FilesService>(
        builder: (_, network, __) => FilesService(
          network: network,
          owner: course.id.toString(),
        ),
        child: FilesView(
          owner: course.id.toString(),
          appBarColor: course.color,
          appBarTitle: course.name,
        ),
      ),
    ),
  );
}