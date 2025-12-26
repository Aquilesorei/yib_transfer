


import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'dart:io';

import '../models/HistoryItem.dart';


class DatabaseManager {
  static const String _dbName   = 'my_database.db'; // Change this to your preferred database name
  static Database? _database;
  static final StoreRef<String, Map<String, dynamic>> _historyItemStoreRef =
  StoreRef<String, Map<String, dynamic>>.main();
  

  

  static List<RecordSnapshot<String, Map<String, dynamic>>> historyItemsSnapshot  = [];


  static Future<void> initializeApp() async{


    
    var historyItems = await getAllHistoryItems();

    // Process history items if needed
    historyItems.where((element) => element["id"] != null).map((e) => HistoryItem.fromJson(e)).toList();

    

  }
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }


// Get a platform-specific directory where persistent app data can be stored
    String dbPath = _dbName;
    if(Platform.isAndroid){
      final appDocumentDir = await getApplicationDocumentsDirectory();
      dbPath = "${appDocumentDir.path}/$_dbName)";
    }


    _database = await databaseFactoryIo.openDatabase(dbPath);
    return _database!;
  }


  static Future<void>  _updateSnapshots() async {
    final db = await database;
    final snapshots = await _historyItemStoreRef.find(db);
    historyItemsSnapshot = snapshots;
  }
  
  static Future<List<Map<String, dynamic>>> getAllHistoryItems() async {
    final db = await database;
    final snapshots = await _historyItemStoreRef.find(db);
    historyItemsSnapshot = snapshots;

    return snapshots.map((snapshot) => snapshot.value).toList();
  }

  static Future<Stream<List<Map<String, dynamic>>>> streamAllHistoryItems() async {
    return _historyItemStoreRef.query().onSnapshots(await database).map((querySnapshots) {
      return querySnapshots
          .map((record) => record.value)
          .toList();
    });
  }

  static Future<void> addHistoryItem(Map<String, dynamic> historyItemData) async {
    final db = await database;
    await _historyItemStoreRef.add(db, historyItemData);
    await _updateSnapshots();

  }

  static Future<void> updateHistoryItem(
      String historyItemId, Map<String, dynamic> updatedData) async {
    final db = await database;
    final snap = historyItemsSnapshot.firstWhere((snapshot) => snapshot.value['id'] == historyItemId);
    final res =  await _historyItemStoreRef.record(snap.key).update(db, updatedData);
    print(res ==  null);
  }
  static Future<void> deleteHistoryItem(String historyItemId) async {
    final db = await database;
    await _historyItemStoreRef.record(historyItemId).delete(db);
    await _updateSnapshots();
  }


  

}