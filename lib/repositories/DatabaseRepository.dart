import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../Repository.dart';

enum RepositoryState { Loaded, Loading, Not_Loaded }

abstract class DatabaseRepository<T extends DBModel> {
  DatabaseRepository(this.path,
      {this.enableSync = false,
      db,
      this.autoInit = true,
      subPath,
      this.useSubPath = false})
      : this.db = db ?? FirebaseDatabase.instance,
        this.secondaryPath = subPath ?? "" {
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
  String _listenerSetTo;

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

    Map val =
        ((await db.reference().child(fullPath).once()).value ?? {}) as Map;

    T _data = mapToModel(val);

    setData(val.length > 0 ? _data : null);
    return _data;
  }

  void changeSubPath(String newSubPath) {
    //print("CHANGING SUBPATH");

    if (!useSubPath) throw ErrorHint("not configured to use subPath");
    if (newSubPath == subPath) {
      //print("SAME SUBPATH");
      return null;
    }

    if (dbListener != null) {
      dbListener.cancel();
      dbListener = null;
    }

    data = null;
    secondaryPath = newSubPath;
    _listenerSetTo = null;

    if(subPath == "" || subPath == null) {
      controller.add(null);
      return;
    } 

    if (autoInit) {
      if (enableSync)
        setListeners();
      else
        fetchData();
    }
  }

  void setListeners() {
    /// This method set all listeners for database Sync
    //print("Set Listener Called");
    //print(
    //    (_listenerSetTo == null ? "null" : _listenerSetTo) + "  -  " + subPath);
    state = RepositoryState.Loading;
    if (useSubPath && (subPath == "" || subPath == null)) return null;
    if (_listenerSetTo == subPath) return null;
    if (dbListener != null) {
      //print("nulling listener");
      dbListener.cancel();
      dbListener = null;
    }
    //print("setting listener");
    _listenerSetTo = subPath;
    dbListener = db.reference().child(fullPath).onValue.listen((event) {
      //print("Data received on repository " + (event.snapshot.value ?? {}).toString());
      Map map = (event.snapshot.value ?? {}) as Map;

      //print("RECEIVED: " + map.toString());

      T model = mapToModel(map);
      setData(map.length > 0 ? model : null);
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
    _listenerSetTo = null;
  }

  // App Output
  Future<String> update(DBModel data, [String customKey]) async {
    /// Is recomended to update data for every object
    try {
      await db
          .reference()
          .child(data.path)
          .child(customKey ?? data.key ?? "")
          .update(data.toMap());
          return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> deleteChild(String key) async {
    /// Deletes the data 'key' on the full path\
    try {
      await db.reference().child(fullPath).child(key).remove();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> deleteData(DBModel data) async {
    /// Deletes the data 'key' on the full path\
    try {
      await db.reference().child(data.path).child(data.key).remove();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
