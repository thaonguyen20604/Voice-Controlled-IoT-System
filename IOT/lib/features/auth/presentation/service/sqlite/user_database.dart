

import 'package:sqflite/sqflite.dart';

import '../../../data/models/user_detail.dart';
import 'database.dart';

class UserDatabase{
  final tableName="Users";

  Future<void> createTable(Database db) async{
    await db.execute("""CREATE TABLE IF NOT EXISTS $tableName(
      "id" INTEGER NOT NULL,
      "fullName" NVARCHAR NOT NULL,
      "userName" NVARCHAR NOT NULL ,
      "email" NVARCHAR NOT NULL,
      "password" NVARCHAR NOT NULL,
      "imgPath" NVARCHAR NOT NULL,
      PRIMARY KEY("id" AUTOINCREMENT)
    );""");
  }

  Future<int?> create({required String fullName,required String userName,required String email, required String password ,required String imgPath}) async{
    final database=await DataBaseService().database;
    return await database?.rawInsert(
      '''INSERT INTO $tableName (fullName,userName,email,password,imgPath) VALUES (?,?,?,?,?)''',[fullName,userName,email,password,imgPath],
    );
  }

  Future<List<UserDetail>?> fetchAll() async{
    final database=await DataBaseService().database;
    final users=await database?.rawQuery(
        '''SELECT * from $tableName'''
    );
    return users?.map((user)=>UserDetail.fromSqfLiteDatabase(user)).toList();
  }


  Future<UserDetail> fetchById(int id)async{
    final database=await DataBaseService().database;
    final user=await database?.rawQuery('''SELECT * FROM $tableName WHERE id = ?''',[id]);
    return UserDetail.fromSqfLiteDatabase(user!.first);
  }

  Future<UserDetail> fetchByEmail(String email)async{
    print(email);
    final database=await DataBaseService().database;
    final user=await database?.rawQuery('''SELECT * FROM $tableName WHERE email = ?''',[email]);
    return UserDetail.fromSqfLiteDatabase(user!.first);
  }


  Future<int?> update({required int id,required String fullName,required String userName,required String email, required String password ,required String imgPath}) async{
    final database=await DataBaseService().database;
    return await database?.update(tableName, {
      'fullName':fullName,
      'userName':userName,
      'email':email,
      'password':password,
      'imgPath':imgPath,

    },where: 'id = ?',
      conflictAlgorithm: ConflictAlgorithm.rollback,
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async{
    final database=await DataBaseService().database;
    await database?.rawDelete('''DELETE FROM $tableName WHERE id = ?''',[id]);
  }



}