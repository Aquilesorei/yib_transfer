

import 'package:mutex/mutex.dart';


class ObjectPool<T> {
  final List<T> _pool = [];
  late final Function() _createObject;


  void initialize( final Function() createObject){
       _createObject = createObject;
  }

  static ObjectPool? _instance;

  static ObjectPool get instance {

    _instance ??= ObjectPool._();
    return _instance!;
  }

  ObjectPool._();



  T acquire() {
    if (_pool.isEmpty) {
      return _createObject();
    } else {
      return _pool.removeLast();
    }
  }

  void release(T obj) {
    _pool.add(obj);
  }
}

/*
class MyObject {
  // Implementation of your object class
}

Future<void> main() async {
  final objectPool = ObjectPool<MyObject>(() => MyObject(), 10);

  MyObject obj1 = await objectPool.acquire();
  MyObject obj2 =  await objectPool.acquire();

  // Use the acquired objects

  objectPool.release(obj1);
  objectPool.release(obj2);
}
*/
