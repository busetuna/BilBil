import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../tabs/stats_tab.dart';
import '../tabs/chart_tab.dart';
import '../tabs/rewards_tab.dart';
import '../tabs/settings_tab.dart';

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Ebeveyn Paneli',
            style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'İstatistik'),
            Tab(icon: Icon(Icons.auto_graph_rounded), text: 'Grafik'),
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Ödüller'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          StatsTab(),
          ChartTab(),
          RewardsTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}