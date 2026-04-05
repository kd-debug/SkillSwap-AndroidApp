import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;
  int _touchedPieIndex = -1;

  final _categoryData = const {
    'Prog.': 12,
    'Design': 8,
    'Lang.': 6,
    'Music': 5,
    'Art': 7,
    'Food': 3,
    'Fit.': 9,
  };

  final _monthlyActivity = const [3, 7, 5, 12, 9, 15, 11, 18, 14, 20, 16, 22];
  final _requestStatus = const {'Pending': 14, 'Accepted': 23, 'Declined': 7};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('📊 Skills per Category',
                'Total skills across all categories'),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 24),
            _sectionHeader('📈 Monthly Activity',
                'Skill requests over the past 12 months'),
            const SizedBox(height: 12),
            _buildLineChart(),
            const SizedBox(height: 24),
            _sectionHeader('🥧 Request Status',
                'Breakdown of all skill exchange requests'),
            const SizedBox(height: 12),
            _buildPieRow(),
            const SizedBox(height: 24),
            _buildSummaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildBarChart() {
    final entries = _categoryData.entries.toList();
    final maxVal =
        _categoryData.values.reduce((a, b) => a > b ? a : b).toDouble();
    final colors = [
      Colors.teal, Colors.indigo, Colors.orange, Colors.purple,
      Colors.amber, Colors.red, Colors.green,
    ];

    return _card(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal + 3,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(entries[i].key,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble() * _anim.value,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colors[i % colors.length].withOpacity(0.6),
                      colors[i % colors.length],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final spots = List.generate(
      _monthlyActivity.length,
      (i) => FlSpot(
          i.toDouble(), _monthlyActivity[i].toDouble() * _anim.value),
    );

    return _card(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 25,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.teal.withOpacity(0.3),
                    Colors.teal.withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) {
                    return const SizedBox();
                  }
                  return Text(months[i],
                      style: const TextStyle(
                          fontSize: 9, color: Colors.grey));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
        ),
      ),
    );
  }

  Widget _buildPieRow() {
    final colors = [Colors.orange, Colors.green, Colors.red];
    final entries = _requestStatus.entries.toList();
    final total = _requestStatus.values.fold(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedPieIndex = response
                              ?.touchedSection?.touchedSectionIndex ??
                          -1;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedPieIndex;
                  final pct = entries[i].value / total;
                  return PieChartSectionData(
                    value: entries[i].value.toDouble() * _anim.value,
                    color: colors[i],
                    radius: isTouched ? 72 : 60,
                    title: '${(pct * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              entries.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text('${entries[i].value} requests',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final summaries = [
      ('44', 'Total Skills', Icons.school, Colors.teal),
      ('44', 'Requests', Icons.swap_horiz, Colors.indigo),
      ('7', 'Categories', Icons.category, Colors.orange),
    ];
    return Row(
      children: summaries
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: s.$4.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: s.$4.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(s.$3, color: s.$4, size: 24),
                        const SizedBox(height: 8),
                        Text(s.$1,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: s.$4)),
                        Text(s.$2,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _card({
    required Widget child,
    double? height,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }
}
