import 'dart:math';

import '../entity/index.dart';

class DataUtil {
  static calculate(
    List<KLineEntity> dataList, {
    List<int> maDayList = const [5, 10, 30],
    List<int> emaDayList = const [5, 10, 30],
    int n = 20,
    k = 2,
        int stochRsiN = 14,
  }) {
    calcMA(dataList, maDayList);
    calcEMA(dataList, emaDayList);
    calcSAR(dataList);
    calcBOLL(dataList, n, k);
    calcVolumeMA(dataList);
    calcKDJ(dataList);
    calcMACD(dataList);
    calcRSI(dataList);
    calcStochRSI(dataList, stochRsiN);
    calcWR(dataList);
    calcCCI(dataList);
    calcOBV(dataList);
  }

  static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
    /// 创建长度为3的数组
    List<double> ma = List<double>.filled(maDayList.length, 0);

    /// 元数据不为空
    if (dataList.isNotEmpty) {
      /// 遍历
      for (int i = 0; i < dataList.length; i++) {
        /// 得到模型
        KLineEntity entity = dataList[i];

        /// 得到收盘价
        final closePrice = entity.close;

        /// 初始化
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        /// 遍历
        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice;
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else {
            entity.maValueList?[j] = 0;
          }
        }
      }
    }

    /// [0.0, 0.0, 0.0]
    /// [0.0, 0.0, 0.0]
    /// [0.0, 0.0, 0.0]
    /// [0.0, 0.0, 0.0]
    /// [35848.18199999999, 0.0, 0.0]
    /// [37386.83, 0.0, 0.0]
    /// [38027.768, 0.0, 0.0]
    /// [39390.258, 0.0, 0.0]
    /// [41434.21800000001, 0.0, 0.0]
    /// [42712.79000000001, 39280.486, 0.0]
    // dataList.sublist(0, 10).forEach((element) => print(element.maValueList));
  }

  static calcEMA(List<KLineEntity> dataList, List<int> emaDayList) {
    double calcEmaValue(double previousEma, double closePrice, int n) {
      // return previousEma * (n - 1) / (n + 1) + closePrice * 2 / (n + 1);
      return (closePrice - previousEma) * (2 / (n + 1)) + previousEma;
      // return closePrice* (2 / (n + 1)) + previousEma * (1 - 2 / (n + 1));
    }
    if (dataList.isNotEmpty) {
      var lastEma = List<double>.filled(emaDayList.length, dataList[0].close);
      for (int i = 1; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.emaValueList = List<double>.filled(emaDayList.length, 0);

        // (close price - LastEMA) * (2 / (n + 1)) + LastEMA
        // if is first, LastEMA is close price
        var ema0 = calcEmaValue(lastEma[0], closePrice, emaDayList[0]);
        var ema1 = calcEmaValue(lastEma[1], closePrice, emaDayList[1]);
        var ema2 = calcEmaValue(lastEma[2], closePrice, emaDayList[2]);

        entity.emaValueList![0] = i >= emaDayList[0] - 1 ? ema0 : 0;
        entity.emaValueList![1] = i >= emaDayList[1] - 1 ? ema1 : 0;
        entity.emaValueList![2] = i >= emaDayList[2] - 1 ? ema2 : 0;

        lastEma = [ema0, ema1, ema2];
      }
    }
  }

  static calcSAR(List<KLineEntity> dataList) {
    if (dataList.isEmpty) return;
    double highPrice = dataList[0].high;
    double lowPrice = dataList[0].low;

    double af = 0.02;
    double sar = lowPrice;
    double ep = highPrice;
    bool uptrend = true;

    for (int i = 1; i < dataList.length; i++) {
      highPrice = dataList[i].high;
      lowPrice = dataList[i].low;
      if (uptrend) {
        if (lowPrice < sar) {
          uptrend = false;
          sar = ep;
          ep = highPrice;
          af = 0.02;
          dataList[i].sar = sar;
        } else {
          sar = sar + af * (ep - sar);
          if (highPrice > ep) {
            ep = highPrice;
            af = af + 0.02 < 0.2 ? af + 0.02 : 0.2;
          }
          dataList[i].sar = sar;
        }
      } else {
        if (highPrice > sar) {
          uptrend = true;
          sar = ep;
          ep = lowPrice;
          af = 0.02;
          dataList[i].sar = sar;
        } else {
          sar = sar - af * (sar - ep);
          if (lowPrice < ep) {
            ep = lowPrice;
            af = af + 0.02 < 0.2 ? af + 0.02 : 0.2;
          }
          dataList[i].sar = sar;
        }
      }
    }
  }

  static void calcBOLL(List<KLineEntity> dataList, int n, int k) {
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.mb = entity.BOLLMA!;
        entity.up = entity.mb! + k * md;
        entity.dn = entity.mb! - k * md;
      }
    }
  }

  static void _calcBOLLMA(int day, List<KLineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      ma += entity.close;
      if (i == day - 1) {
        entity.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.BOLLMA = ma / day;
      } else {
        entity.BOLLMA = null;
      }
    }
  }

  static void calcMACD(List<KLineEntity> dataList) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  static void calcRSI(List<KLineEntity> dataList) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  static void calcKDJ(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  static void calcWR(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }

  static void calcCCI(List<KLineEntity> dataList) {
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount +=
            (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3)
                .abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }

  static void calcOBV(List<KLineEntity> dataList) {

    if (dataList.isNotEmpty) {
      /// 标准计算方式
      dataList[0].obv = dataList[0].vol;
      /// binance 计算方式d
      // dataList[0].obv = 0;
    }
    for (int i = 1; i < dataList.length; i++) {
      var curEntity = dataList[i];
      var preEntity = dataList[i-1];
      if (curEntity.close > preEntity.close) {
        curEntity.obv = (preEntity.obv ?? 0) + curEntity.vol;
      } else if (curEntity.close < preEntity.close) {
        curEntity.obv = (preEntity.obv??0) - curEntity.vol;
      } else {
        curEntity.obv = preEntity.obv;
      }
    }
  }

  /// 计算 StochRSI 14,3,3
  static void calcStochRSI(List<KLineEntity> dataList, int stochRsiN) {
    if (dataList.length < stochRsiN) {
      return;
    }


    /// 如果还没有计算过RSI，先计算RSI
    if (dataList[0].rsi == null) {
      calcRSI(dataList);
    }

    // Stoch RSI = (Current RSI - Lowest RSI)/(Highest RSI - Lowest RSI)

    double lowestRSI = double.maxFinite;
    double highestRSI = double.minPositive;
    double sum = 0.0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (entity.rsi != null) {
        lowestRSI = min(lowestRSI, entity.rsi!);
        highestRSI = max(highestRSI, entity.rsi!);

        if (i >= stochRsiN) {
          entity.stochRsi = (entity.rsi! - lowestRSI) / (highestRSI - lowestRSI) * 100;
          sum += entity.stochRsi!;
          if (i > (stochRsiN + 3) && dataList[i - 3].stochRsi != null) {
            sum -= dataList[i - 3].stochRsi!;
          }
          entity.maStochRsi = sum / 3;
          /// 优化从0开始的问题
          if (i == stochRsiN && entity.stochRsi == 0) {
            entity.stochRsi = null;
            entity.maStochRsi = null;
          }
        }
      }
    }


    // for (var value in dataList.sublist(13, 13 + 10)) {
    //   print("rsi:${value.rsi} stochRsi:${value.stochRsi} maStochRsi:${value.maStochRsi}");
    // }


  }
}
