import 'dart:math';

double annuityPayment(double principal, double monthlyRate, int nMonths, [double residual = 0]) {
  if (monthlyRate == 0) return (principal - residual) / nMonths;
  final r = monthlyRate;
  final df = pow(1 + r, nMonths).toDouble();
  return (principal * r * df - residual * r) / (df - 1);
}

void main() {
  double capital = 250000;
  int n = 240;
  double rate = 3.23;
  double ins = 0.34;
  double fees = 1.0;
  double guar = 1.4;

  double monthlyRate = rate / 100 / 12;
  double mensHorsAss = annuityPayment(capital, monthlyRate, n);
  double mensAss = capital * (ins / 100) / 12;
  double totalPaidHorsAss = mensHorsAss * n;
  double totalInterest = totalPaidHorsAss - capital;
  double totalAss = mensAss * n;
  double feesEuro = capital * fees / 100;
  double guarEuro = capital * guar / 100;
  double totalCost = totalInterest + totalAss + feesEuro + guarEuro;

  print('Mensualite hors ass: $mensHorsAss');
  print('Total Interets: $totalInterest');
  print('Total Ass: $totalAss');
  print('Total Cost: $totalCost');
}
