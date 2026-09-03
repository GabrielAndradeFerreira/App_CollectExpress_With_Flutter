import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLLECT',
          style: GoogleFonts.poppins(
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 3, color: AppColors.green),
            const SizedBox(width: 4),
            Text(
              'XPRESS',
              style: GoogleFonts.poppins(
                color: const Color(0xFF77A644),
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
