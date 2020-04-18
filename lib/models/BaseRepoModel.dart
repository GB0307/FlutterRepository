import 'package:flutter/foundation.dart';

typedef SortFunction<T> = int Function(T m1, T m2);

/// The base model for any data retrieved from the Repository
///
/// This class contains base functions and variables to work with
/// the repository, extend it and add your own variables, set then in
/// the constructor or in the setData function.
abstract class DBModel {
  /// Key of this model in the Database.
  final String key;

  /// The path to the Database folder.
  final String path;

  /// The Map retrieved from the database.
  final Map rawData;

  /// Create a model from a Map retrived from the Database.
  DBModel.fromMap(this.path, this.key, this.rawData) {
    setData();
  }

  /// Used to test your model.
  ///
  /// Override it and add constant values to your variables, so you can have
  /// a Dummy model to test it.
  DBModel.dummyData(this.path, this.key) : rawData = {};

  DBModel(this.path, this.key) : rawData = {};

  /// Get all of your variables and turn it in a map.
  ///
  /// For consistency, it's important to keep the same scheme from the data
  /// retrieved from the database.
  Map<String, dynamic> toMap();

  bool validateModel();

  @protected

  /// Converts a map into a set of Variables.
  ///
  /// This function is used to set the variables in your class with the rawData.
  void setData();
}

/// A model that is a list of other models.
///
/// If you need a model that is a List of other models, use DBModelList<T>,
/// with it you can retrieve a list of DBModel's from a database directory.
abstract class DBModelList<T extends DBModel> extends DBModel {
  /// Used to test your model.
  ///
  /// Override it and add constant values to your variables, so you can have
  /// a Dummy model to test it.
  DBModelList.dummyData(String path, String key, Map rawData)
      : super.dummyData(path, key);

  /// Create a model from a Map retrived from the Database.
  DBModelList.fromMap(String path, String key, Map rawData)
      : super.fromMap(path, key, rawData);

  @protected

  /// Map of keys and models.
  Map<String, T> data = {};

  /// Items in the list.
  List<T> get items => data.values.toList() ?? <T>[];

  /// Number of items in this list.
  int get length => data.length;

  @override

  /// Convert each value in the map into a new Model <T>.
  void setData() {
    rawData.forEach((key, value) {
      data[key] = newModel(key, value);
    });
  }

  @protected

  /// Converts the data into a single Model <T>
  T newModel(String key, Map data);

  @override

  /// Get all of your variables and turn it in a map.
  ///
  /// For consistency, it's important to keep the same scheme from the data
  /// retrieved from the database.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    data.keys.forEach((key) {
      map[key] = data[key].toMap();
    });
    return map;
  }

  /// Retrieves a model based on the index or key.
  T operator [](dynamic key) {
    if (key is String) {
      return data[key];
    } else if (key is int) {
      return items[key];
    }
  }

  @override
  bool validateModel() {
    var r = true;
    data.forEach((k, v) {
      if (r && !v.validateModel()) r = false;
    });
    return r;
  }
}

/// SortedDBModelList sort the data from the database, so you have an ordered list.
abstract class SortedDBModelList<T extends DBModel> extends DBModelList {
  /// Used to test your model.
  ///
  /// Override it and add constant values to your variables, so you can have
  /// a Dummy model to test it.
  SortedDBModelList.dummyData(String path, String key, Map rawData,
      {this.sortFunction, this.inverse = false})
      : super.dummyData(path, key, rawData) {
    sortKeys();
  }

  /// Create a model from a Map retrived from the Database.
  SortedDBModelList.fromMap(String path, String key, Map rawData,
      {this.sortFunction, this.inverse = false})
      : super.fromMap(path, key, rawData) {
    sortKeys();
  }

  /// Sort Function responsible for sorting the data.
  SortFunction<T> sortFunction;

  @protected

  /// Whether the data is inverted or not.
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

  /// Retrieves a model based on the index or key.
  T operator [](dynamic key) {
    /// Use the operator to get the data handled
    if (key is String) {
      return data[key];
    } else if (key is int) {
      return data[sortedKeys[key]];
    }
  }
}
