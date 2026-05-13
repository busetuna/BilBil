import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/learning/presentations/screens/main_navigation.dart';
import 'firebase_options.dart';
import 'data/models/user_model.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'features/learning/presentations/providers/auth_provider.dart';
import 'features/learning/presentations/screens/splash_screen.dart';
import 'services/firestore/firestore_service.dart';
import 'services/rewards/reward_service.dart';
import 'services/stats/stats_service.dart';
import 'services/lives/lives_service.dart';
import 'services/theme/theme_service.dart';
import 'services/asr/vosk_asr_service.dart';
import 'services/asr/whisper_asr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());

  final firestoreService = FirestoreService();

  final rewardService = RewardService();
  await rewardService.init();

  final statsService = StatsService();
  await statsService.init();

  final livesService = LivesService();
  await livesService.init();

  final themeService = ThemeService();
  await themeService.init();

  final voskAsrService = VoskAsrService();
  final whisperAsrService = WhisperAsrService();

  // Uygulama açılışında zaten oturum açıksa bulut verisini yükle
  final fbUser = fb.FirebaseAuth.instance.currentUser;
  if (fbUser != null) {
    final cloudData = await firestoreService.loadUserData(fbUser.uid);
    if (cloudData != null) {
      await statsService.loadFromCloud(cloudData['stats'] as Map<String, dynamic>?);
      await rewardService.loadFromCloud(cloudData['rewards'] as Map<String, dynamic>?);
      await livesService.loadFromCloud(cloudData['lives']);
    }
    statsService.setCloudSync(fbUser.uid, firestoreService);
    rewardService.setCloudSync(fbUser.uid, firestoreService);
    livesService.setCloudSync(fbUser.uid, firestoreService);
  }

  runApp(MyApp(
    firestoreService: firestoreService,
    rewardService: rewardService,
    statsService: statsService,
    livesService: livesService,
    themeService: themeService,
    voskAsrService: voskAsrService,
    whisperAsrService: whisperAsrService,
  ));
}

class MyApp extends StatelessWidget {
  final FirestoreService firestoreService;
  final RewardService rewardService;
  final StatsService statsService;
  final LivesService livesService;
  final ThemeService themeService;
  final VoskAsrService voskAsrService;
  final WhisperAsrService whisperAsrService;

  const MyApp({
    super.key,
    required this.firestoreService,
    required this.rewardService,
    required this.statsService,
    required this.livesService,
    required this.themeService,
    required this.voskAsrService,
    required this.whisperAsrService,
  });

  Future<void> _onSignedIn(String uid) async {
    final cloudData = await firestoreService.loadUserData(uid);
    if (cloudData != null) {
      await statsService.loadFromCloud(cloudData['stats'] as Map<String, dynamic>?);
      await rewardService.loadFromCloud(cloudData['rewards'] as Map<String, dynamic>?);
      await livesService.loadFromCloud(cloudData['lives']);
    }
    statsService.setCloudSync(uid, firestoreService);
    rewardService.setCloudSync(uid, firestoreService);
    livesService.setCloudSync(uid, firestoreService);
  }

  Future<void> _onSignedOut() async {
    statsService.clearCloudSync();
    rewardService.clearCloudSync();
    livesService.clearCloudSync();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(firestoreService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            registerUseCase: RegisterUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
            authRepository: authRepository,
            onSignedIn: _onSignedIn,
            onSignedOut: _onSignedOut,
          ),
        ),
        ChangeNotifierProvider<RewardService>.value(value: rewardService),
        ChangeNotifierProvider<StatsService>.value(value: statsService),
        ChangeNotifierProvider<LivesService>.value(value: livesService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<VoskAsrService>.value(value: voskAsrService),
        ChangeNotifierProvider<WhisperAsrService>.value(value: whisperAsrService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) => MaterialApp(
          title: 'Bilbil',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: KeyedSubtree(
            key: ValueKey(themeService.current.id),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) return const SplashScreen();
                if (authProvider.isLoggedIn) return const MainNavigation();
                return const SplashScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}