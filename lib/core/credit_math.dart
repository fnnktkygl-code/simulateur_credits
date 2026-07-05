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
    hi = 100.0; // max 10000% TAEG pour les très petits crédits très chargés (ex: prêt 200€ sur 1 mois avec 50€ frais)
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

// End of credit_math.dart
