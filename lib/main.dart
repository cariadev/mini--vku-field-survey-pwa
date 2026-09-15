import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/survey_repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive
  await Hive.initFlutter();

  // Khởi tạo Repository
  final repository = await SurveyRepository.init();

  // Khởi chạy UI ứng dụng ngay lập tức
  runApp(VkuFieldSurveyApp(repository: repository));

  // Tải dữ liệu ngầm từ Google Sheet về sau khi UI đã lên
  repository.fetchFromGoogleSheets();
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
