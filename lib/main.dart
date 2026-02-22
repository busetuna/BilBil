import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/learning/presentations/screens/main_navigation.dart';
import 'firebase_options.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/models/user_model.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'features/learning/presentations/providers/auth_provider.dart';
import 'features/learning/presentations/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive'ı başlat
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authLocalDataSource = AuthLocalDataSource();
    final authRepository = AuthRepositoryImpl(authLocalDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            registerUseCase: RegisterUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
            authRepository: authRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Bilbil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const SplashScreen();
            }
            if (authProvider.isLoggedIn) {
              return const MainNavigation();
            }
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}