// Builds square launcher-icon sources from the gym logo.
//
//   dart run tool/make_app_icon.dart
//   dart run flutter_launcher_icons
//
// assets/images/logo.png is a wide image with large empty margins, so it is cropped to
// the drawn logo and centred on a square canvas (a non-square source would be stretched).
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/images/logo.png').readAsBytesSync())!;

  // Bounding box of the dark (drawn) pixels.
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (final p in src) {
    if (p.a > 0 && p.luminanceNormalized < 0.5) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }
  final logo = img.copyCrop(src, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
  // The logo is black artwork on a light-grey background: turn darkness into opacity so the
  // background disappears and edges stay smooth.
  for (final p in logo) {
    final ink = ((1 - p.luminanceNormalized) * 1.1).clamp(0.0, 1.0); // light grey -> ~0
    final alpha = (ink < 0.08 ? 0.0 : ink) * (p.a / 255);
    p
      ..r = 0
      ..g = 0
      ..b = 0
      ..a = (alpha * 255).round();
  }
  stdout.writeln('Logo area: ${logo.width}x${logo.height} at ($minX,$minY)');

  // Full icon (iOS, legacy Android): logo fills 82% of a white square.
  _write(_square(logo, 1024, 0.82, background: img.ColorRgb8(255, 255, 255)), 'assets/images/app_icon.png');

  // Android adaptive foreground: keep the logo inside the 66% safe zone, transparent background.
  _write(_square(logo, 1024, 0.62), 'assets/images/app_icon_foreground.png');
}

img.Image _square(img.Image logo, int size, double fill, {img.Color? background}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: background ?? img.ColorRgba8(0, 0, 0, 0));
  final scale = size * fill / math.max(logo.width, logo.height);
  final w = (logo.width * scale).round(), h = (logo.height * scale).round();
  final resized = img.copyResize(logo, width: w, height: h, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, resized, dstX: (size - w) ~/ 2, dstY: (size - h) ~/ 2);
  return canvas;
}

void _write(img.Image image, String path) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote $path');
}
