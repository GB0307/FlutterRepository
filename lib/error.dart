class RepositoryError implements Exception {
  final String code;

  RepositoryError._(this.code);

  RepositoryError.defaultError(e): this.code = "DEFAULT"{
    print(e);
  }

}