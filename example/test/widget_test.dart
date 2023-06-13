// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('TEST EMA', (WidgetTester tester) async {
    /// bybit
    // List<double> closingPrices = [26921.28, 26927.22, 26917.82, 26935.23, 26960.63, 26948.36, 26906.76];
    /// OKX
    // List<double> closingPrices = [25636.00, 25658.01, 25698.00, 25681.00, 25683.00, ];

    //
    List<double> closingPrices = [27145.8, 27193.3, 16820.9, 16916.4, 17225.8, ];
    double ema = closingPrices[0];
    double multiplier = 2 / (closingPrices.length + 1);

    for (int i = 1; i < closingPrices.length; i++) {
      print("cur EMA is: ${ema.toStringAsFixed(2)}");
      ema = (closingPrices[i] - ema) * multiplier + ema;
    }

    print("The ${closingPrices.length}-day EMA is: ${ema.toStringAsFixed(1)}");
  });

  testWidgets('Test SAR', (widgetTester) async {
    List<double> highPrices = [25.10, 25.20, 25.50, 25.70, 25.80, 25.90, 26.00, 26.20, 26.50, 26.80];
    List<double> lowPrices = [24.50, 24.60, 24.80, 25.00, 25.10, 25.20, 25.30, 25.50, 25.80, 26.10];
    double af = 0.02;
    double sar = lowPrices[0];
    double ep = highPrices[0];
    bool uptrend = true;
    List<double> sarValues = [sar];
    for (int i = 1; i < highPrices.length; i++) {
      if (uptrend) {
        if (lowPrices[i] < sar) {
          uptrend = false;
          sar = ep;
          ep = highPrices[i];
          af = 0.02;
          sarValues.add(sar);
        } else {
          sar = sar + af * (ep - sar);
          if (highPrices[i] > ep) {
            ep = highPrices[i];
            af = af + 0.02 < 0.2 ? af + 0.02 : 0.2;
          }
          sarValues.add(sar);
        }
      } else {
        if (highPrices[i] > sar) {
          uptrend = true;
          sar = ep;
          ep = lowPrices[i];
          af = 0.02;
          sarValues.add(sar);
        } else {
          sar = sar - af * (sar - ep);
          if (lowPrices[i] < ep) {
            ep = lowPrices[i];
            af = af + 0.02 < 0.2 ? af + 0.02 : 0.2;
          }
          sarValues.add(sar);
        }
      }
    }
    print('highPrices: ${highPrices.length} ${sarValues.length}\n $sarValues');
  });
}
