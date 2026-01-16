import 'package:flutter/material.dart';
import 'package:pharmatest/cities_page.dart';
import 'package:pharmatest/pharmacy_repository.dart';
import 'package:pharmatest/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pharmatest/update_service.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback? toggleTheme;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const HomePage({
    super.key,
    required this.prefs,
    this.toggleTheme,
    required this.themeModeNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<String>> _regionsFuture;
  late final PharmacyRepository _pharmacyRepository;

  @override
  void initState() {
    super.initState();
    _pharmacyRepository = PharmacyRepository(widget.prefs);
    loadRegions();
  }

  Future<void> loadRegions() async {
    setState(() {
      _regionsFuture = _pharmacyRepository
          .getRegionsAndTowns()
          .then((map) => map.keys.toList())
          .catchError(
            (e) => throw Exception('Erreur de chargement des régions'),
          );
    });
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.brightness_7; // Soleil pour mode clair
      case ThemeMode.dark:
        return Icons.brightness_3; // Lune pour mode sombre
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Mode système';
      case ThemeMode.dark:
        return 'Mode clair';
      case ThemeMode.system:
        return 'Mode sombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeModeNotifier,
                builder: (context, currentMode, child) {
                  return IconButton(
                    icon: Icon(_getThemeIcon(currentMode)),
                    onPressed: widget.toggleTheme,
                    tooltip: _getThemeTooltip(currentMode),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).iconTheme.color,
                ),
                onSelected: (value) {
                  if (value == 'update') {
                    UpdateService().checkForUpdates(
                      context,
                      showNoUpdate: true,
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(
                            Icons.system_update,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 12),
                          Text('Vérifier les mises à jour'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            pinned: true,
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "PHARMACIES DE GARDE",
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage('assets/icon.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<String>>(
              future: _regionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildRegionGrid(snapshot.data!);
                } else {
                  return _buildErrorState("Aucune région n'a été trouvée.");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: AppTheme.modernCard(context),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chargement des régions...',
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: AppTheme.modernCard(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                error,
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: loadRegions,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: AppTheme.modernButton(context),
                  child: Text(
                    'Réessayer',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionGrid(List<String> regions) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${regions.length} Régions du Cameroun',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sélectionnez votre région',
                  style: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final regionName = regions[index];
              return _buildRegionCard(regionName, index);
            },
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRegionCard(String regionName, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            debugPrint("Région '$regionName' sélectionnée");
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CitiesPage(region: regionName, prefs: widget.prefs),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            );
          },
          child: Container(
            decoration: AppTheme.modernCard(context),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getRegionIcon(regionName),
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    regionName,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRegionIcon(String regionName) {
    switch (regionName) {
      case "ADAMAOUA":
        return Icons.landscape;
      case "CENTRE":
        return Icons.business_center;
      case "EST":
        return Icons.forest;
      case "EXTRÊME-NORD":
        return Icons.north;
      case "LITTORAL":
        return Icons.beach_access;
      case "NORD":
        return Icons.bubble_chart;
      case "NORD-OUEST":
        return Icons.bubble_chart;
      case "OUEST":
        return Icons.terrain;
      case "SUD":
        return Icons.south;
      case "SUD-OUEST":
        return Icons.waves;
      default:
        return Icons.location_on;
    }
  }
}
