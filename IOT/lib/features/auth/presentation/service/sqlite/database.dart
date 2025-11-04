import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:home_automation_app/features/auth/presentation/service/sqlite/user_database.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';



class DataBaseService{
  static Database? _database;

  Future<String> get fullPath async{
    const name="app.db";
    final path =await getDatabasesPath();
    return join(path,name);
  }

  Future<Database?> get database async{
    if(_database!=null){
      await saveDb(await fullPath);
      return _database;
    }
    _database=await initDatabase ();
    return null;
  }

  Future<void> deleteDatabase(String path) =>
      databaseFactory.deleteDatabase(path);


  Future<Database> initDatabase() async{
    final path=await fullPath;
    await copyDbFromAssets();
    // await deleteDatabase(path);
    await saveDb(path);
    var database=await openDatabase(path,
        version: 1,
        onCreate: create,
        singleInstance: true
    );
    return database;
  }

  Future<void> create(Database db, int version) async {
    await UserDatabase().createTable(db);
  }

  saveDb(path)async{
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        return;
      }
    }
    try{
      File ourDBFile=File(
          path
      );
      Directory? folderPathForDBFile=Directory("/storage/emulated/0/Download/");
      await folderPathForDBFile.create();
      await ourDBFile.copy("/storage/emulated/0/Download/app.db");
    }catch(e){
      print(e);
    }
  }

  Future<void> copyDbFromAssets() async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          return;
        }
      }

      final dbPath = await fullPath;
      final file = File(dbPath);

      print(file);

      if (await file.exists()) {
        return;
      }

      ByteData data = await rootBundle.load('assets/app.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);


      await file.writeAsBytes(bytes);
      print('Cơ sở dữ liệu đã được sao chép từ assets.');
    } catch (e) {
      print('Lỗi khi sao chép cơ sở dữ liệu từ assets: $e');
    }
  }
}