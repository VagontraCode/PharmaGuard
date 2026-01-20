import 'package:flutter/material.dart';
import 'package:pharmatest/pharmacies_page.dart';
import 'package:pharmatest/pharmacy_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pharmatest/theme.dart';

class CitiesPage extends StatefulWidget {
  final String region;
  final SharedPreferences prefs;

  const CitiesPage({super.key, required this.region, required this.prefs});

  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  final ScrollController _scrollController = ScrollController();
  late final PharmacyRepository _pharmacyRepository;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pharmacyRepository = PharmacyRepository(widget.prefs);
    loadCities();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  late Future<List<String>> _citiesFuture;
  Future<void> loadCities() async {
    setState(() {
      _citiesFuture = _pharmacyRepository.getRegionsAndTowns().then(
        (regionsAndTowns) => regionsAndTowns[widget.region] ?? [],
      );
    });
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Villes',
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.w700,
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
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          FutureBuilder<List<String>>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSliver();
              } else if (snapshot.hasError) {
                return _buildErrorSliver(snapshot.error.toString());
              } else {
                final cities = snapshot.data ?? [];
                final filteredCities = cities
                    .where(
                      (city) => city.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();
                return filteredCities.isEmpty
                    ? _buildEmptySearchSliver()
                    : _buildCitiesSliverList(filteredCities);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: AppTheme.modernCard(context),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher une ville...',
            hintStyle: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).primaryColor,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          cursorColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: AppTheme.modernCard(context),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: .3),
              ),
            ),
            child: Hero(
              tag: 'region-icon-${widget.region}',
              child: Icon(
                AppTheme.getRegionIcon(widget.region),
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.region,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ville${(widget.region.length > 1) ? 's' : ''} disponible dans la région',
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
        ],
      ),
    );
  }

  Widget _buildCitiesSliverList(List<String> cities) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    if (isDesktop) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            mainAxisExtent: 100, // Fixed height for consistency in grid
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final cityName = cities[index];
            return _buildCityItem(cityName, index, isGrid: true);
          }, childCount: cities.length),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cityName = cities[index];
        return _buildCityItem(cityName, index);
      }, childCount: cities.length),
    );
  }

  Widget _buildCityItem(String cityName, int index, {bool isGrid = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // If in grid, let the grid handle spacing (margins are 0 or minimal internal)
      // If in list, keep original margins
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            debugPrint("Ville '$cityName' sélectionnée");
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PharmaciesPage(
                      region: widget.region,
                      city: cityName,
                      prefs: widget.prefs,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.modernCard(context),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cityName,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.region,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
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
              SizedBox(height: 16),
              Text(
                'Chargement des villes...',
                style: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildErrorSliver(String error) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        padding: EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: AppTheme.modernCard(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 16),
                Text(
                  error,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: loadCities,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      ),
    );
  }

  SliverToBoxAdapter _buildEmptySearchSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge!.color!.withValues(alpha: .5),
            ),
            SizedBox(height: 16),
            Text(
              "Aucune ville trouvée pour \"$_searchQuery\"",
              style: GoogleFonts.inter(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge!.color!.withValues(alpha: .7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
