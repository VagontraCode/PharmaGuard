import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:pharmatest/pharmacy_model.dart';

/// Helper function to check if a string contains only whitespace or punctuation.
/// This is useful for cleaning up extracted text that might contain
/// only separators or empty spaces.
bool _isOnlyWhitespaceOrPunctuation(String text) {
  return text.isEmpty ||
      text == ':' ||
      text == '-' ||
      text.replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '').isEmpty;
}

// ignore_for_file: deprecated_member_use
// This ignore is for the `html` package's `querySelectorAll` which might
// internally use deprecated methods, but it's not directly in our control.

class PharmacyService {
  final String baseUrl =
      'https://www.annuaire-medical.cm/fr/pharmacies-de-garde';

  Future<Map<String, List<String>>> fetchRegionsAndTowns() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final document = parse(response.body);
      final regionsAndTowns = <String, List<String>>{};
      String? currentRegion;

      final ulElements = document.querySelectorAll('ul.phar_perso');

      for (var ul in ulElements) {
        final regionElement = ul.querySelector('li > span.info');
        if (regionElement != null) {
          currentRegion = regionElement.text.trim();
          regionsAndTowns[currentRegion] = [];
        }

        final townElements = ul.querySelectorAll('li > a.info');
        for (var townElement in townElements) {
          final townName = townElement.text.trim();
          if (currentRegion != null) {
            regionsAndTowns[currentRegion]!.add(townName);
          }
        }
      }
      return regionsAndTowns;
    } else {
      throw Exception('Failed to load regions and towns');
    }
  }

  String _getFrenchDayName(int dayIndex) {
    final days = [
      "dimanche",
      "lundi",
      "mardi",
      "mercredi",
      "jeudi",
      "vendredi",
      "samedi",
    ];
    return days[dayIndex];
  }

  Future<List<Pharmacy>> fetchPharmacies(String region, String town) async {
    final townUrl =
        '$baseUrl/${_formatUrl(region)}/pharmacies-de-garde-${_formatUrl(town)}';
    final response = await http.get(Uri.parse(townUrl));
    debugPrint('link: $townUrl');

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final pharmacies = <Pharmacy>[];

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final dutyPeriod =
          "${_getFrenchDayName(now.weekday % 7)} ${now.day}/${now.month}/${now.year} - 8h00 au "
          "${_getFrenchDayName(tomorrow.weekday % 7)} ${tomorrow.day}/${tomorrow.month}/${tomorrow.year} - 8h00";

      debugPrint('Duty Period: $dutyPeriod');

      final articles = document.querySelectorAll('.article');

      for (var article in articles) {
        final lineDiv =
            article.querySelector('.ligne_pers') ??
            article.querySelector('.pharma_line');

        if (lineDiv == null) {
          continue;
        }

        final nameElement = lineDiv.querySelector('strong');
        final name = nameElement?.text.trim().replaceAll(' ', '') ?? 'N/A';

        final phoneNumbers = lineDiv.querySelectorAll(
          'span[style*="float: right"]',
        );
        final phone = phoneNumbers
            .map((span) => span.text.trim().replaceAll(' ', ''))
            .join(' ');

        String address = 'N/A';
        final lineDivText = lineDiv.text.replaceAll(' ', ' ').trim();

        debugPrint('Raw text: $lineDivText');

        final townPosition = lineDivText.toLowerCase().indexOf(
          town.toLowerCase(),
        );

        if (townPosition != -1) {
          final textAfterTown = lineDivText
              .substring(townPosition + town.length)
              .trim();
          String cleanedText = textAfterTown.replaceAll(':', '').trim();

          if (cleanedText.isEmpty ||
              cleanedText == String.fromCharCode(160) ||
              cleanedText == ' ' ||
              _isOnlyWhitespaceOrPunctuation(cleanedText)) {
            address = town;
          } else {
            String potentialAddress = cleanedText;
            final phoneRegex = RegExp(r'\d{2,}[\s\d-]{6,}\s*$');
            final phoneMatch = phoneRegex.firstMatch(potentialAddress);

            if (phoneMatch != null) {
              potentialAddress = potentialAddress
                  .substring(0, phoneMatch.start)
                  .trim();
            }

            potentialAddress = potentialAddress
                .replaceAll(RegExp(r'\d{2,}[\s\d-]{6,}'), '')
                .trim();

            if (potentialAddress.isNotEmpty &&
                !_isOnlyWhitespaceOrPunctuation(potentialAddress)) {
              address = potentialAddress;
            } else {
              address = town;
            }
          }
        } else {
          final namePosition = lineDivText.indexOf(name);
          if (namePosition != -1) {
            final textAfterName = lineDivText
                .substring(namePosition + name.length)
                .trim();

            final textWithoutPhone = textAfterName
                .replaceAll(RegExp(r'\d{2,}[\s\d-]{6,}'), '')
                .trim();

            if (textWithoutPhone.isNotEmpty &&
                !_isOnlyWhitespaceOrPunctuation(textWithoutPhone)) {
              address = textWithoutPhone;
            } else {
              address = town;
            }
          } else {
            address = town;
          }
        }

        if (address.isNotEmpty &&
            address != 'N/A' &&
            address != String.fromCharCode(160)) {
          address = address
              .replaceAll(RegExp(r'\s+'), ' ')
              .replaceAll(RegExp(r'^[:\s-]+|[:-\s]+$'), '')
              .trim();

          if (address.isEmpty || _isOnlyWhitespaceOrPunctuation(address)) {
            address = town;
          }
        } else {
          address = town;
        }

        if (name != 'N/A' && phone.isNotEmpty) {
          pharmacies.add(
            Pharmacy(
              name: name,
              address: address,
              phone: phone,
              scheduleDescription: dutyPeriod,
            ),
          );
        }
      }
      return pharmacies;
    } else {
      throw Exception('Failed to load pharmacies for $town');
    }
  }

  String _formatUrl(String text) {
    return text
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('é', 'e')
        .replaceAll("ê", "e")
        .replaceAll('è', 'e')
        .replaceAll('à', 'a')
        .replaceAll(':', '')
        .replaceAll('ô', 'o')
        .replaceAll("'", "-")
        .replaceAll('ï', 'i')
        .replaceAll("---", '-')
        .replaceAll("ȇ", "e")
        .replaceAll("ë", "e");
  }
}
