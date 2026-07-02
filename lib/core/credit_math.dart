import 'dart:math';

/// Format a number as EUR currency (no decimals).
String euro(double n) {
  final formatted = n.abs().toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}\u00A0',
  );
  final sign = n < 0 ? '-' : '';
  return '$sign$formatted\u00A0€';
}

/// Format a number as EUR currency (2 decimals).
String euro2(double n) {
  final intPart = n.truncate().abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}\u00A0',
  );
  final decPart = (n.abs() - n.abs().truncate()).toStringAsFixed(2).substring(2);
  final sign = n < 0 ? '-' : '';
  return '$sign$intPart,$decPart\u00A0€';
}

/// Format as percentage with [d] decimal places.
String pct(double n, [int d = 2]) {
  return '${n.toStringAsFixed(d).replaceAll('.', ',')}\u00A0%';
}

double clamp(double v, double mn, double mx) => max(mn, min(mx, v));

double lerp(double x, double x0, double y0, double x1, double y1) {
  return y0 + (y1 - y0) * ((x - x0) / (x1 - x0));
}

/// Standard amortizing monthly payment (annuity), optional balloon (residual).
double annuityPayment(double principal, double monthlyRate, int nMonths, [double residual = 0]) {
  if (monthlyRate == 0) return (principal - residual) / nMonths;
  final r = monthlyRate;
  final df = pow(1 + r, nMonths).toDouble();
  return (principal * r * df - residual * r) / (df - 1);
}

/// Actuarial TAEG solver using bisection.
/// Returns annual TAEG as percentage, or null if not solvable.
double? solveTAEG(double netAdvanced, double payment, int nMonths, [double balloon = 0]) {
  double npv(double i) {
    if (i <= -0.9999) return double.infinity;
    double v = 0;
    for (int k = 1; k <= nMonths; k++) {
      v += payment / pow(1 + i, k);
    }
    if (balloon != 0) {
      v += balloon / pow(1 + i, nMonths);
    }
    return v - netAdvanced;
  }

  double lo = -0.05, hi = 1.5;
  double flo = npv(lo), fhi = npv(hi);
  if (flo.isNaN || fhi.isNaN || flo * fhi > 0) {
    hi = 5;
    fhi = npv(hi);
    if (flo * fhi > 0) return null;
  }

  double mid = 0;
  for (int iter = 0; iter < 100; iter++) {
    mid = (lo + hi) / 2;
    final fmid = npv(mid);
    if (fmid.abs() < 1e-6) break;
    if (flo * fmid < 0) {
      hi = mid;
      fhi = fmid;
    } else {
      lo = mid;
      flo = fmid;
    }
  }
  return (pow(1 + mid, 12) - 1).toDouble() * 100;
}

/// Lookup value on a piecewise-linear curve defined by sorted (x,y) points.
double curveLookup(List<List<double>> points, double x) {
  if (x <= points.first[0]) return points.first[1];
  if (x >= points.last[0]) return points.last[1];
  for (int i = 0; i < points.length - 1; i++) {
    final x0 = points[i][0], y0 = points[i][1];
    final x1 = points[i + 1][0], y1 = points[i + 1][1];
    if (x >= x0 && x <= x1) return lerp(x, x0, y0, x1, y1);
  }
  return points.last[1];
}

// ===================== RATE CURVES =====================

/// Immo default rate curve (Banque de France T1-T2 2026).
const immoRatePoints = <List<double>>[[84, 2.60], [180, 2.95], [240, 3.23], [300, 3.50]];

double immoDefaultRate(int months) => curveLookup(immoRatePoints, months.toDouble());

/// Immo usure caps (T3 2026, Banque de France).
double immoUsureCap(int months) {
  if (months < 120) return 4.07;
  if (months < 240) return 4.57;
  return 5.29;
}

/// Auto credit rate curve.
const autoCreditRatePoints = <List<double>>[[12, 3.2], [24, 3.6], [36, 3.9], [48, 4.3], [60, 4.7], [72, 5.1], [84, 5.5]];

/// Auto LOA rate curve.
const autoLoaRatePoints = <List<double>>[[24, 4.6], [36, 5.0], [48, 5.5], [60, 6.0], [72, 6.4]];

/// Auto VR curve (% du prix).
const autoVrPoints = <List<double>>[[24, 58], [36, 48], [48, 38], [60, 30], [72, 24]];

/// Conso usure cap by amount bracket.
double consoUsureCap(double capital) {
  if (capital <= 3000) return 23.56;
  if (capital <= 6000) return 15.87;
  return 8.67;
}

String consoTrancheLabel(double capital) {
  if (capital <= 3000) return '≤ 3 000 €';
  if (capital <= 6000) return '3 001 € à 6 000 €';
  return '> 6 000 €';
}
