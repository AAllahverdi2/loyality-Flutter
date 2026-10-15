import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    this.onPress,
    this.bonusAmount = '0',
    this.cardNumber = '',
    super.key,
  });

  final VoidCallback? onPress;
  final String bonusAmount;
  final String cardNumber;

  // Exact 1-to-1 Ionicons "gift" SVG from @expo/vector-icons
  static const String _giftSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M200 144h40V104a40 40 0 10-40 40Z" fill="none"/>
  <path d="M352 104a40 40 0 00-80 0v40h40a40 40 0 0040-40Z" fill="none"/>
  <path d="M80 416a64 64 0 0064 64h92a4 4 0 004-4V292a4 4 0 00-4-4H88a8 8 0 00-8 8Z" fill="#C91C1C"/>
  <path d="M240 252V144h32v108a4 4 0 004 4h140a47.93 47.93 0 0016-2.75 48.09 48.09 0 0032-45.25V192a48 48 0 00-48-48h-40.54a2 2 0 01-1.7-3A72 72 0 00256 58.82 72 72 0 00138.24 141a2 2 0 01-1.7 3H96a48 48 0 00-48 48v16a48.09 48.09 0 0032 45.25A47.93 47.93 0 0096 256h140a4 4 0 004-4Zm32-148a40 40 0 1140 40h-40ZM197.14 64.1A40 40 0 01240 104v40h-40a40 40 0 01-2.86-79.89Z" fill="#C91C1C"/>
  <path d="M276 480h92a64 64 0 0064-64V296a8 8 0 00-8-8H276a4 4 0 00-4 4v184a4 4 0 004 4Z" fill="#C91C1C"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 24,
      ),
      height: 275,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -10,
            left: 20,
            right: 20,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.5 : 0.3,
                    ),
                    offset: const Offset(0, 10),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ),

            Positioned.fill(
            child: GestureDetector(
              onTap: onPress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4B5563),
                      Color(0xFF111827),
                      Color(0xFF000000),
                    ],
                    stops: [0.0, 0.6, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        width: 200,
                        height: 200,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),

                      // decorativeCircle2: bottom: -80, left: -20, width: 250, height: 250
                      Positioned(
                        bottom: -80,
                        left: -20,
                        width: 250,
                        height: 250,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),

                      // Content column
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // cardTopSection: logo tinted white
                            Image.asset(
                              'assets/logo.png',
                              width: 160,
                              height: 44,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),

                            // barcodePanel
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // panelHeaderRow
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // bonusLabelContainer
                                      Row(
                                        children: [
                                          SvgPicture.string(
                                            _giftSvg,
                                            width: 18,
                                            height: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tr('home_my_bonuses'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // panelAmountText
                                      Text(
                                        bonusAmount,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC91C1C),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // panelDivider
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    height: 1,
                                    color: const Color(0xFFE5E7EB),
                                    width: double.infinity,
                                  ),

                                  // Real barcode from number
                                  BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: cardNumber.replaceAll(' ', ''),
                                    width: double.infinity,
                                    height: 64,
                                    drawText: false,
                                    color: Colors.black,
                                    errorBuilder: (context, error) => Image.asset(
                                      'assets/barkod.png',
                                      width: double.infinity,
                                      height: 64,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // cardNumberSmall
                                  Text(
                                    cardNumber,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
