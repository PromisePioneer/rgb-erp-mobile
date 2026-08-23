# RGB ERP Mobile — Coding Conventions

## Stack

- **State management**: `provider` (bukan Riverpod/Bloc). Pola: `ChangeNotifier` state class (immutable, punya `copyWith`) + `ChangeNotifier` notifier class yang membungkus repository.
- **Routing**: `go_router`, didefinisikan terpusat di `lib/navigation/app_router.dart` via `initRouter(AuthNotifier)`. Redirect logic (auth guard) juga di situ.
- **HTTP**: `dio`, satu instance dibuat di `ApiClientFactory` (`lib/core/network/api_client.dart`) dengan `AuthInterceptor` (nambahin Bearer token) dan `LoggingInterceptor`.
- **Storage**: `flutter_secure_storage` dibungkus `StorageService` (`lib/core/services/storage_service.dart`) — semua key disentralisasi di `AppConstants` (`lib/core/constants/app_constants.dart`), jangan hardcode string key storage baru di luar situ.
- **Error handling**: semua error dari Dio dikonversi ke `ApiException` via `ApiException.fromDioException()` (`lib/core/network/api_exception.dart`). Selalu lempar/`catch` `ApiException`, jangan biarkan `DioException` bocor ke layer presentation.
- **Lokasi**: `geolocator` dibungkus `LocationService` (`lib/core/services/location_service.dart`), mengembalikan `LocationData` (lat/lng/accuracy/timestamp) dan sudah handle permission + service-disabled dengan `LocationException`.
- **Biometrik device** (fingerprint/Face ID untuk login, BUKAN face recognition server): `local_auth` dibungkus `BiometricService`.
- **Model/JSON**: entity ditulis manual `extends Equatable` dengan `fromJson`/`toJson` manual (lihat `lib/features/auth/domain/entities/user.dart`).

## Struktur folder per fitur (feature-first, bukan layer-first di root)

```
lib/features/<nama_fitur>/
├── data/
│   └── repositories/
│       └── <nama_fitur>_repository.dart
├── domain/
│   ├── entities/
│   │   └── <entity>.dart
│   └── domain.dart
└── presentation/
    ├── providers/
    │   └── <nama_fitur>_provider.dart
    ├── screens/
    │   └── <nama_fitur>_screen.dart
    └── widgets/
        └── (widget spesifik fitur ini saja)
```

## Pola menambah API call baru

1. **Tambah endpoint constant** di `lib/core/network/api_endpoints.dart`
2. **Tambah/lengkapi kelas `*Api`** di `lib/core/di/injection.dart` dengan pola:
   ```dart
   Future<Map<String, dynamic>> methodName(...) async {
     try {
       final response = await _dio.post(...);
       return response.data;
     } on DioException catch (e) {
       throw ApiException.fromDioException(e);
     }
   }
   ```
3. **Repository** memanggil `*Api`, parse response jadi entity
4. **Provider** (state + notifier) memanggil repository, set `isLoading`/`error`, dan `notifyListeners()`

## Desain UI

- **Warna**: Pakai token dari `AppColors` (sudah ada `success/warning/danger/info` + `rgbPrimary`/`rbmPrimary`)
- **Spacing**: `AppSpacing`, `AppRadius`
- **Komponen siap pakai**: `lib/shared/widgets/` (`PrimaryButton`, `AppTextField`, `ConfirmDialog`)
- **Bahasa**: Indonesia untuk semua teks UI

## Routing

Tambah `GoRoute` baru di `lib/navigation/app_router.dart`. Auth guard global sudah handle redirect, tidak perlu guard manual per-route.

## Camera & Permission

Repo ini **belum punya** dependency `camera` (yang ada `image_picker` dan `mobile_scanner`).

Jika membuat fitur yang memakai kamera/lokasi, tambahkan permission di:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## Testing

Test ada di `test/`, mirror path dari `lib/features/...`. Pakai `flutter_test` untuk unit test `copyWith` dan transisi state.
