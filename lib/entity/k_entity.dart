import 'candle_entity.dart';
import 'kdj_entity.dart';
import 'macd_entity.dart';
import 'obv_entity.dart';
import 'rsi_entity.dart';
import 'rw_entity.dart';
import 'stoch_rsi_entity.dart';
import 'volume_entity.dart';
import 'cci_entity.dart';

class KEntity
    with
        StochRSIEntity,
        OBVEntity,
        CandleEntity,
        VolumeEntity,
        KDJEntity,
        RSIEntity,
        WREntity,
        CCIEntity,
        MACDEntity{}
