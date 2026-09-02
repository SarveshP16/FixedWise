/// One sampled point on a deposit's growth curve (Detail screen's chart).
class ChartPoint {
  const ChartPoint(this.date, this.value);

  final DateTime date;
  final double value;
}
