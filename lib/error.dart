class RepositoryError implements Exception {
  final String code;
  final Exception e;

  RepositoryError._(this.code) : e = null;

  RepositoryError.defaultError(this.e) : this.code = "DEFAULT" {
    print(e);
  }
}
