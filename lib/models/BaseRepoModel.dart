import 'package:flutter/cupertino.dart';

typedef SortFunction<T> = int Function(T m1, T m2);

abstract class DBModel {
  final String key;
  final String path;
  final Map rawData;

  DBModel.fromMap(this.path, this.key, this.rawData) {
    /// Creates a DBModel from a database Map
    setData();
  }

  DBModel.dummyData(this.path, this.key): rawData={};

  Map<String, dynamic> toMap();

  @protected

  /// Converts a map into a set of Variables
  void setData();
}

abstract class DBModelList<T extends DBModel> extends DBModel {
  DBModelList.dummyData(String path, String key, Map rawData)
      : super.dummyData(path, key);
  DBModelList.fromMap(String path, String key, Map rawData) : super.fromMap(path, key, rawData);

  @protected
  Map<String, T> data = {};
  List<T> get items => data.values.toList() ?? <T>[];
  int get length => data.length;

  @override
  void setData() {
    /// for multiple items, set the subpath
    rawData.forEach((key, value) {
      data[key] = newModel(key, value);
    });
  }

  @protected
  T newModel(String key, Map data);

  @override
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    data.keys.forEach((key) {
      map[key] = data[key].toMap();
    });
    return map;
  }

  //Operators
  T operator [](dynamic key) {
    if (key is String) {
      return data[key];
    } else if (key is int) {
      return items[key];
    }
  }
}

abstract class SortedDBModelList<T extends DBModel> extends DBModelList {
  SortedDBModelList.dummyData(String path, String key, Map rawData,
      {this.sortFunction, this.inverse = false})
      : super.dummyData(path, key, rawData) {
    sortKeys();
  }
  SortedDBModelList.fromMap(String path, String key, Map rawData,
      {this.sortFunction, this.inverse = false})
      : super.fromMap(path, key, rawData) {
    sortKeys();
  }

  SortFunction<T> sortFunction;
  @protected
  bool inverse;

  @protected
  List<String> sortedKeys = [];

  @protected
  sortKeys() {
    if (sortFunction != null) {
      sortedKeys = (data ?? {}).keys.toList()
        ..sort((a, b) => sortFunction(data[a], data[b]));
    } else {
      sortedKeys = (data ?? {}).keys.toList()..sort((a, b) => a.compareTo(b));
    }
    if (inverse) sortedKeys = sortedKeys.reversed.toList();
  }

  T operator [](dynamic key) {
    /// Use the operator to get the data handled
    if (key is String) {
      return data[key];
    } else if (key is int) {
      return data[sortedKeys[key]];
    }
  }
}
