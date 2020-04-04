import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../Repository.dart';

enum RepositoryState { Loaded, Loading, Not_Loaded }

abstract class DatabaseRepository<T extends DBModel> {
  DatabaseRepository(this.path,
      {this.enableSync = false, db, this.autoInit = true, subPath, this.useSubPath=false})
      : this.db = db ?? FirebaseDatabase.instance,
        this.secondaryPath = subPath ?? ""{
    if (autoInit != null && autoInit) {
      onInit();
    }
  }

  // Class Configuration
  bool enableSync = false;
  bool autoInit = true;
  RepositoryState state = RepositoryState.Not_Loaded;
  bool get listenerSet => dbListener != null;
  final bool useSubPath;

  // Database Variables
  final String path;
  @protected
  String secondaryPath;
  String get fullPath => path[path.length - 1] == "/"
      ? path + (useSubPath ? secondaryPath : "")
      : path + "/" + (useSubPath ? secondaryPath : "");
  String get subPath => secondaryPath;
  @protected
  FirebaseDatabase db;
  StreamSubscription<Event> dbListener;

  // Data Variables
  @protected
  T data;
  T get currentData => data;

  // Stream Variables
  @protected
  StreamController<T> controller = StreamController.broadcast();
  Stream<T> get stream => controller.stream;

  void onInit() {
    /// Called after the constructor
    if (enableSync)
      setListeners();
    else
      fetchData();
  }

  Future<T> fetchData() async {
    /// Use the method to get the database data once, ignoring any cached data
    state = RepositoryState.Loading;
    data = null;
    controller.add(null);

    Map val = ((await db.reference().child(fullPath).once()).value ?? {})  as Map;

    T _data = mapToModel(val);

    setData(val.length > 0? _data : null);
    return _data;
  }

  void changeSubPath(String newSubPath) {
    if (!useSubPath) throw ErrorHint("not configured to use subPath");
    if (dbListener != null) {
      dbListener.cancel();
      dbListener = null;
    }
    data = null;
    controller.add(null);
    secondaryPath = newSubPath;

    if (!useSubPath || subPath != "" || subPath != null) if (autoInit) {
      if (enableSync)
        setListeners();
      else
        fetchData();
    }
  }

  void setListeners() {
    /// This method set all listeners for database Sync
    enableSync = true;
    state = RepositoryState.Loading;
    if(useSubPath && (subPath == "" || subPath == null)) return;
    dbListener = db.reference().child(fullPath).onValue.listen((event) {
      Map map = (event.snapshot.value ?? {}) as Map;
      
      T model = mapToModel(map);
      setData(map.length > 0? model : null);
    });
  }

  /// Implement this method to convert the map from the Database to the object T
  T mapToModel(Map dbData);

  @protected
  void setData(T val) {
    /// Method used to set the data and send to the stream
    state = RepositoryState.Loaded;
    data = val;
    controller.add(data);
  }

  void dispose() {
    if (dbListener != null) {
      dbListener.cancel();
      dbListener = null;
    }
    data = null;
    controller.close();
  }

  // App Output
  Future<String> update(DBModel data) async {
    /// Is recomended to update data for every object
    

    try {
      await db
          .reference()
          .child(data.path)
          .child(data.key)
          .update(data.toMap());
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> deleteChild(String key) async {
    /// Deletes the data 'key' on the full path\
    try {
      await db.reference().child(fullPath).child(key).remove();
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> deleteData(DBModel data) async {
    /// Deletes the data 'key' on the full path\
    try {
      await db.reference().child(data.path).child(data.key).remove();
    } catch (e) {
      return e.toString();
    }
  }
}
