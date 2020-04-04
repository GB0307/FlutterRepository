import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../Repository.dart';

enum RepositoryState { Loaded, Loading, Not_Loaded }

abstract class DatabaseRepository<T extends DBModel> {
  DatabaseRepository(this.path,
      {this.enableSync = false, db, this.autoInit = true, subPath})
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

  // Database Variables
  final String path;
  @protected
  String secondaryPath;
  String get fullPath => path[path.length - 1] == "/"
      ? path + secondaryPath
      : path + "/" + secondaryPath;
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

    Map val = (await db.reference().child(fullPath).once()).value as Map;

    T _data = mapToModel(val);

    setData(_data);
    return _data;
  }

  void setListeners() {
    /// This method set all listeners for database Sync
    state = RepositoryState.Loading;
    dbListener = db.reference().child(fullPath).onValue.listen((event) {
      T model = mapToModel((event.snapshot.value ?? {}) as Map);
      setData(model);
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
    dbListener.cancel();
    dbListener = null;
    data = null;
    controller.close();
  }

  // App Output
  //TODO: Implement set data method
  Future<String> update(Map data, {String subpath = ""}) {}
}