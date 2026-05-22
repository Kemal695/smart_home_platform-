import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class EnergyPage extends ConsumerStatefulWidget {
  const EnergyPage({super.key});

  @override
  ConsumerState<EnergyPage> createState() => _EnergyPageState();
}

class _EnergyPageState extends ConsumerState<EnergyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Energy & Billing')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(cs),
          const SizedBox(height: 24),
          Text('Daily Consumption (kWh)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _EnergyChart()),
          const SizedBox(height: 24),
          Text('Billing History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildBillingRow('This Month', '\$45.20', cs),
          _buildBillingRow('Last Month', '\$52.80', cs),
          _buildBillingRow('Average', '\$48.50', cs),
          const SizedBox(height: 16),
          Text('Top Devices by Usage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildDeviceUsage('Living Room Light', '12.4 kWh', 0.35, cs),
          _buildDeviceUsage('AC Unit', '28.2 kWh', 0.55, cs),
          _buildDeviceUsage('Water Heater', '18.7 kWh', 0.2, cs),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ColorScheme cs) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(
          icon: Icons.electric_bolt,
          label: 'Today',
          value: '2.4 kWh',
          color: Colors.amber,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon: Icons.attach_money,
          label: 'Est. Cost',
          value: '\$1.52',
          color: Colors.green,
        )),
      ],
    );
  }

  Widget _buildBillingRow(String label, String amount, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDeviceUsage(String name, String usage, double fraction, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: const TextStyle(fontSize: 14)),
            Text(usage, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fraction, minHeight: 6, backgroundColor: cs.surfaceContainerHighest),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _EnergyChart extends StatelessWidget {
  final List<double> _values = const [1.2, 0.8, 0.6, 1.0, 1.8, 2.4, 2.1, 1.5, 1.2, 1.0, 0.9, 0.7, 0.5, 0.4, 1.1, 2.0, 2.8, 3.2, 2.6, 1.8, 1.4, 1.2, 1.0, 0.8];
  final List<String> _labels = const ['0', '2', '4', '6', '8', '10', '12', '14', '16', '18', '20', '22'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = _values.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            getTitlesWidget: (v, _) {
              final idx = v.toInt() ~/ 2;
              return idx < _labels.length ? Text(_labels[idx], style: const TextStyle(fontSize: 9)) : const SizedBox();
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_values.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(getTooltipItems: (touched) => touched.map((t) => LineTooltipItem('${t.y.toStringAsFixed(1)} kWh', const TextStyle(color: Colors.white, fontSize: 12))).toList()),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: cs.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}
