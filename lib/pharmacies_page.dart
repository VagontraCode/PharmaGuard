import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:pharmatest/pharmacy_repository.dart';
import 'package:pharmatest/pharmacy_model.dart';
import 'package:pharmatest/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PharmaciesPage extends StatefulWidget {
  final String region;
  final String city;
  final SharedPreferences prefs;

  const PharmaciesPage({
    super.key,
    required this.region,
    required this.city,
    required this.prefs,
  });

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<Pharmacy>> _pharmaciesFuture;
  late final PharmacyRepository _pharmacyRepository;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _pharmacyRepository = PharmacyRepository(widget.prefs);
    loadPharmacies();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.forward ||
          _scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        // Logique à implémenter si nécessaire
      }
    });
  }

  Future<void> loadPharmacies() async {
    setState(() {
      _pharmaciesFuture = _pharmacyRepository.getPharmacies(
        widget.region,
        widget.city,
      );
      _pharmaciesFuture.then((_) {
        _lastUpdate = _pharmacyRepository.getLastFetchTime(
          widget.region,
          widget.city,
        );
      });

      // Save location for background fetching
      widget.prefs.setString('last_region', widget.region);
      widget.prefs.setString('last_city', widget.city);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          _buildDataFutureBuilder(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadPharmacies,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[600]
            : Theme.of(context).primaryColor,
        tooltip: 'Rafraîchir les pharmacies',
        child: Icon(
          Icons.refresh,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      pinned: true,
      expandedHeight: 120.0,
      actions: [
        IconButton(
          icon: Icon(
            _pharmacyRepository.isFavoriteCity(widget.region, widget.city)
                ? Icons.star
                : Icons.star_border,
            color: Theme.of(context).primaryColor,
          ),
          tooltip: 'Ajouter aux favoris',
          onPressed: () async {
            await _pharmacyRepository.toggleFavoriteCity(
              widget.region,
              widget.city,
            );
            setState(() {}); // Rebuild to update icon

            if (mounted) {
              final isFav = _pharmacyRepository.isFavoriteCity(
                widget.region,
                widget.city,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFav
                        ? '${widget.city} ajoutée aux favoris (Mise à jour auto activée)'
                        : '${widget.city} retirée des favoris',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Pharmacies',
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
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.modernCard(context),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              AppTheme.getRegionIcon(widget.region),
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.city,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.region,
                  style: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pharmacies de garde disponibles',
                  style: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                if (_lastUpdate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mis à jour: ${_formatDate(_lastUpdate!)}',
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDataFutureBuilder() {
    return FutureBuilder<List<Pharmacy>>(
      future: _pharmaciesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSliver();
        } else if (snapshot.hasError) {
          return _buildErrorSliver(snapshot.error.toString());
        } else if (snapshot.hasData) {
          final pharmacies = snapshot.data!;
          return pharmacies.isEmpty
              ? _buildEmptySliver()
              : _buildPharmaciesSliverList(pharmacies);
        } else {
          return _buildErrorSliver("Aucune donnée disponible.");
        }
      },
    );
  }

  Widget _buildPharmaciesSliverList(List<Pharmacy> pharmacies) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    if (isDesktop) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            mainAxisSpacing: 12,
            crossAxisSpacing: 16,
            mainAxisExtent: 350, // Fixed height for consistency
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final pharmacy = pharmacies[index];
            return PharmacyCard(pharmacy: pharmacy, index: index, isGrid: true);
          }, childCount: pharmacies.length),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final pharmacy = pharmacies[index];
        return PharmacyCard(pharmacy: pharmacy, index: index);
      }, childCount: pharmacies.length),
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
              const SizedBox(height: 16),
              Text(
                'Chargement des pharmacies...',
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
        height: 235,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.modernCard(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                Text(
                  "Erreur de connexion",
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: loadPharmacies,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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

  SliverToBoxAdapter _buildEmptySliver() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.modernCard(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_pharmacy,
                  color: Theme.of(context).primaryColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune pharmacie trouvée',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pour ${widget.city}',
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
        ),
      ),
    );
  }
}

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final int index;
  final bool isGrid;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.index,
    this.isGrid = false,
  });

  Future<void> _launchPhoneCall(
    BuildContext context,
    String phoneNumber,
  ) async {
    try {
      final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          _showSnackBar(
            context,
            'Impossible de lancer l\'appel vers $cleanNumber',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Erreur lors du lancement de l\'appel');
      }
    }
  }

  Future<void> _openMap(BuildContext context, String? address) async {
    if (address == null || address.isEmpty) return;

    final encodedAddress = Uri.encodeComponent(address);
    final platform = Theme.of(context).platform;
    Uri uri;

    if (platform == TargetPlatform.android) {
      // "geo:" scheme lets Android choose the best app (Google Maps, Waze, etc.)
      uri = Uri.parse("geo:0,0?q=$encodedAddress");
    } else if (platform == TargetPlatform.iOS) {
      uri = Uri.parse("https://maps.apple.com/?q=$encodedAddress");
    } else {
      uri = Uri.parse("https://www.google.com/maps/search/$encodedAddress");
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps web if the native intent fails
        final fallbackUrl = Uri.parse(
          'https://www.google.com/maps/search/$encodedAddress',
        );
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Erreur lors de l\'ouverture de la carte');
      }
    }
  }

  Future<void> _sharePharmacyInfo(BuildContext context) async {
    final text =
        "${pharmacy.name}\n📍 ${pharmacy.address}\n📞 ${pharmacy.phone}\n🕒 ${pharmacy.scheduleDescription}";
    await Share.share(text);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final text = "${pharmacy.name}\n${pharmacy.phone}\n${pharmacy.address}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Informations copiées !'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: Duration(seconds: 1),
      ),
    );
  }

  List<String> _extractPhoneNumbers(String text) {
    final String cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    final phoneRegex = RegExp(r'\d{9,}');
    return phoneRegex
        .allMatches(cleaned)
        .map((match) => match.group(0)!)
        .expand(
          (number) => List.generate(
            (number.length / 9).floor(),
            (i) => number.substring(i * 9, (i + 1) * 9),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      margin: isGrid 
          ? EdgeInsets.zero 
          : const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: AppTheme.modernCard(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPharmacyNameRow(context),
                const SizedBox(height: 16),
                _buildInfoRow(context, Icons.location_on, pharmacy.address),
                const SizedBox(height: 12),
                _buildPhoneInfoRow(context, pharmacy.phone),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  pharmacy.scheduleDescription,
                ),
                const Spacer(),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row _buildPharmacyNameRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.local_pharmacy,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            pharmacy.name,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
            size: 18,
          ),
          onPressed: () => _copyToClipboard(context),
          tooltip: 'Copier les infos',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge!.color!.withValues(alpha: 0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInfoRow(BuildContext context, String phoneText) {
    final phoneNumbers = _extractPhoneNumbers(phoneText);

    if (phoneNumbers.isEmpty) {
      return _buildInfoRow(context, Icons.phone, phoneText);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.phone, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phoneNumbers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: phoneNumbers.map((number) {
                    return ActionChip(
                      label: Text(
                        number,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      onPressed: () => _launchPhoneCall(context, number),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasAddress = pharmacy.address.isNotEmpty;

    return Row(
      children: [
        if (hasAddress) ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map, size: 18),
              label: const Text('Localiser'),
              onPressed: () => _openMap(
                context,
                "${pharmacy.name}, ${pharmacy.address}, Cameroun",
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Partager'),
            onPressed: () => _sharePharmacyInfo(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Theme.of(context).primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
