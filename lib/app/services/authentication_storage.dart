import 'package:schulcloud/core/data.dart';

/// A service that offers storage of an email and an access token. It doesn't do
/// the actual login.
class AuthenticationStorageService {
  static const _emailId = Id<String>('email');
  static const _tokenId = Id<String>('token');

  final _inMemory = InMemoryStorage<String>();
  CachedRepository<String> _repo;

  AuthenticationStorageService() {
    _repo = CachedRepository<String>(
      cache: _inMemory,
      source: SharedPreferences('authentication'),
    )..loadItemsIntoCache();
  }

  String get email => _inMemory.get(_emailId);
  String get token => _inMemory.get(_tokenId);
  bool get isAuthorized => token != null;

  set email(String email) => _repo.update(_emailId, email);
  set token(String token) => _repo.update(_tokenId, token);

  Stream<void> get onCredentialsChangedStream => _inMemory.fetch(_tokenId);

  void logout() => _repo.clear();
}