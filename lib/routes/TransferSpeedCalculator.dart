
import 'dart:async';

class TransferSpeedCalculator {

  int _previousBytes = 0;
  int _currentBytes = 0;
  late Timer _timer;

  int speed =0;



  void Function(int speed)?  listen;
  TransferSpeedCalculator() {
    _timer = Timer.periodic(const Duration(seconds: 1), _calculateSpeed);
  }

  void _calculateSpeed(Timer timer) {
    int bytesPerSecond = _currentBytes - _previousBytes;
    speed = bytesPerSecond;
    if(listen != null){
      listen!(bytesPerSecond);
    }
    _previousBytes = _currentBytes;
  }

  // Simulate the update of sent bytes (you should replace this with your actual code)
  void updateSentBytes(int sentBytes) {
    _currentBytes = sentBytes;
  }

  void cancel() {
    _timer.cancel();
  }
}


