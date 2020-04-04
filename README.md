# Repository

This package is used to easily port firebase database data into Dart classes.

## Getting Started

### 1 - Install the package
First, install the package by placing it in the flutter dependencies in your pubspec.yaml
```Pubspec.yaml
Repository:
    git: https://github.com/GB0307/FlutterRepository.git
```

### 2 - Creating models
For each "class" in your database, create a data model class extending DBModel for it, for an example, a class User, with the variables name and email:
```Dart
class UserModel extends DBModel{
  UserModel.fromMap(String key, Map rawData) : super(key, rawData);
  
  String name;
  String email;
  
  @override
  void setData() {
      title = rawData['title'];
      email = rawData['email'];
  }
  
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email
    }
  }
}
```

#### 3.1 - Creating a List of models
If you are actually retrieving a list of classes from the database, you will need another class called DBModelList or SortedDBModelList
```Dart
// Use DBModelList if sorting data is not needed
class UserModelList extends DBModelList<UserModel> {
  UserModelList.fromMap(String key, Map rawData) : super.fromMap(key, rawData);

  @override
  UserModel newModel(String key, Map data) {
    return UserModel.fromMap(key, data);
  }
}

// Or, SortedDBModelList if you need it

class SortedUserModelList extends SortedDBModelList<UserModel>{
  SortedUserModelList.fromMap(String key, Map rawData) : super.fromMap(key, rawData, inverse: false, sortFunction: (userA, userB) => userA.title.compareTo(userB.title));

  @override
  UserModel newModel(String key, Map data) {
    return UserModel.fromMap(key, data);
  }
}
```

### 4 - Creating the repository
To create a repository, extend the class Repository, provide the database path and some optional configs
```Dart
class UserRepository extends DatabaseRepository<UserModel> {
  UserRepository(String subPath)
      : super('users', subPath: subPath, enableSync: false, autoInit: true);

  @override
  UserModel mapToModel(Map dbData) {
    return new UserModel.fromMap(subPath, dbData);
  }
}
```
The repository class has some configurations: 
- Path: the path is the database path to the data.
- subPath: is used to access a subitem located at path (so the full path becomes '$path/$subPath'), it is used when you have a list of items (users in this example) but only want to retrieve one from the database at a time.
- enableSync: make the repository sync with the database, sending a stream event everytime something is changed
- autoInit: set the repository to fetch the data automaticaly

Methods:
- Future<DBModel> fetchData(): ignores the current data and force update from the database, it is used when you dont have enableSync active and/or autoInit is disabled, you can also use it if you need a Future<DBModel> return type instead of a stream event.
- void changeSubPath(String newSubPath): remove the data and listeners from the last subPath and change it to the new one, if you have autoInit enabled it will automaticaly set the new listeners if enableSync is enabled. if not, it will fetch the new data instead.
- void onInit(): 
- void dispose():
  
Properties:
- RepositoryState state:
- DBModel currentData: 
- bool enableSync:
- bool autoInit:
- String path:
- String get subPath:
- String get fullPath:
- Stream<DBModel> get stream:
...

