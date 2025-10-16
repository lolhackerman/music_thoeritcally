import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/interval_finder.dart';

class CenteredScalableFinder extends StatelessWidget {
  final Size designSize;
  final double maxWidthFraction;
  final double maxHeightFraction;
  final String? firstNote;
  final String? secondNote;
  final ValueListenable<String?> firstNoteVN;
  final ValueListenable<String?> secondNoteVN;

  const CenteredScalableFinder({
    super.key,
    required this.designSize,
    required this.maxWidthFraction,
    required this.maxHeightFraction,
    required this.firstNote,
    required this.secondNote,
    required this.firstNoteVN,
    required this.secondNoteVN,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth * maxWidthFraction;
      final maxH = constraints.maxHeight * maxHeightFraction;
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: designSize.width, height: designSize.height,
            child: ValueListenableBuilder<String?>(
              valueListenable: firstNoteVN,
              builder: (_, n1, __) => ValueListenableBuilder<String?>(
                valueListenable: secondNoteVN,
                builder: (_, n2, __) => IntervalFinder(firstNote: n1, secondNote: n2),
              ),
            ),
          ),
        ),
      );
    });
  }
}
