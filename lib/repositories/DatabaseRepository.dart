import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../flutter_repository.dart';

enum RepositoryState { Loaded, Loading, Not_Loaded }

/// Basic repository class.
///
/// Extend it to create a repository for your models.
abstract class DatabaseRepository<T extends DBModel> {
  /// Repository constructor
  ///
  /// [path] is the database path where the repository will fetch the data.
  /// set [enableSync] to `true` if you need to update your data to be in sync with the database.
  /// set [autoInit] to false if you want to initialize the listeners of fetch the data manually.
  /// set [useSubpath] if you have a list of items in the database but will fetch only one at once.
  /// [subPath] is the path that will be fetched if [useSubPath] is `true`.
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

  /// Whether the listener is set or not
  bool get listenerSet => dbListener != null;
  final bool useSubPath;

  // Database Variables
  final String path;
  @protected
  String secondaryPath;

  /// Full database path ([path]/[subPath])
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

  /// Get the current model in the repository.
  T get currentData => data;

  // Stream Variables
  @protected
  StreamController<T> controller = StreamController.broadcast();

  /// Get a stream of models.
  Stream<T> get stream => controller.stream;

  void onInit() {
    /// Called after the constructor
    if (enableSync)
      setListeners();
    else
      fetchData();
  }

  /// Fetch the data
  ///
  /// It ignores the current model and fetch a new one.
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

  /// Changes the [subPath].
  ///
  /// It will set the [currentData] to `null` and retrieve a new data if [autoInit] is enabled.
  /// If the [newSubPath] is `null` or empty, it will just remove the currentModel and remove every
  /// database listener.
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

    if (subPath == "" || subPath == null) {
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

  /// This method set all listeners for database Sync.
  void setListeners() {
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

  /// Update [data] in the database.
  Future<String> update(DBModel data) async {
    if (!data.validateModel()) throw "INVALID MODEL";
      try {
        await db
            .reference()
            .child(data.path)
            .child(data.key)
            .update(data.toMap());
        return null;
      } catch (e) {
        return e.toString();
      }
  }

  /// Deletes the data [key] on the full path.
  Future<String> deleteChild(String key) async {
    try {
      await db.reference().child(fullPath).child(key).remove();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes the [model] from the database.
  Future<String> deleteData(DBModel model) async {
    /// Deletes the data 'key' on the full path\
    try {
      await db.reference().child(data.path).child(data.key).remove();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
