import 'package:flutter/material.dart';
import 'services/survey_repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = SurveyRepository();
  await repository.init();

  runApp(VkuFieldSurveyApp(repository: repository));
}

class VkuFieldSurveyApp extends StatelessWidget {
  final SurveyRepository repository;
  const VkuFieldSurveyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VKU Field Survey PWA',
      debugShowCheckedModeBanner: false,
      theme: buildVkuTheme(),
      home: HomeScreen(repository: repository),
    );
  }
}
