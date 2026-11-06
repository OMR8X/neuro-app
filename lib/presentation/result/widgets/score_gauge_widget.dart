import 'dart:math' as math;

import 'package:neuro_app/core/resources/styles/assets_resources.dart';
import 'package:neuro_app/core/resources/styles/font_styles_manager.dart';
import 'package:neuro_app/core/resources/styles/spaces_resources.dart';
import 'package:flutter/material.dart';

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.percentage,
    required this.displayText,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.timeTaken,
  });

  final double percentage;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final String displayText;
  final Duration timeTaken;
  @override
  Widget build(BuildContext context) {
    final String timeTakenLabel = _formatDuration(timeTaken);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: SpacesResources.s20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxWidth / 2.25,
            child: CustomPaint(
              painter: ArcGaugePainter(
                percentage: percentage,
                backgroundColor: theme.colorScheme.surfaceContainer,
                foregroundColor: theme.colorScheme.onSurface,
                strokeWidth: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(height: SpacesResources.s10),
                  Text(
                    " $displayText  ",
                    style: TextStylesResources.largeTitle.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeightResources.black,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: timeTakenLabel,
                          style: TextStylesResources.subTitle.copyWith(
                            fontSize: FontSizeResources.s12,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeightResources.medium,
                          ),
                        ),
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1.5, right: 4),
                            child: Image.asset(
                              UIImagesResources.timerUIIcon,
                              height: FontSizeResources.s12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

class ArcGaugePainter extends CustomPainter {
  ArcGaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.foregroundColor,
    this.strokeWidth = 24.0,
  });

  final double percentage;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.bottomCenter(Offset.zero);
    final radius = size.shortestSide - strokeWidth / 2;

    // Draw tick marks around the arc
    _drawTickMarks(canvas, center, radius, size);

    // Draw the background arc
    _drawBackgroundArc(canvas, center, radius);

    // Draw the gradient progress arc
    _drawProgressArc(canvas, center, radius, size);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius, Size size) {
    const int tickCount = 25;
    final tickPaint =
        Paint()
          ..color = backgroundColor.withValues(alpha: 0.3)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= tickCount; i++) {
      final angle = math.pi + (math.pi * i / tickCount);
      final isLargeTick = i % 5 == 0;
      final innerRadius = radius + strokeWidth / 2 + (isLargeTick ? 8 : 12);
      final outerRadius = radius + strokeWidth / 2 + (isLargeTick ? 18 : 16);

      final startPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      tickPaint.strokeWidth = isLargeTick ? 2.5 : 1.5;
      canvas.drawLine(startPoint, endPoint, tickPaint);
    }
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Main background arc
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, -math.pi, false, backgroundPaint);
  }

  void _drawProgressArc(Canvas canvas, Offset center, double radius, Size size) {
    if (percentage <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = math.pi * percentage.clamp(0.0, 1.0);

    // Simple solid color progress arc
    final progressPaint =
        Paint()
          ..color = foregroundColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, -sweepAngle, false, progressPaint);

    // Add a subtle inner highlight
    final highlightPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth * 0.3;

    final highlightRect = Rect.fromCircle(center: center, radius: radius - strokeWidth * 0.25);
    canvas.drawArc(highlightRect, 0, -sweepAngle, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant ArcGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
