# Aplikasi Flutter Dio Provider MVC

Aplikasi Flutter ini dibangun menggunakan pola desain **MVC (Model-View-Controller)**, manajemen state **Provider**, dan **Dio** untuk komunikasi jaringan yang efisien. Aplikasi ini terintegrasi dengan backend API berbasis Laravel untuk menangani Otentikasi Pengguna dan operasi CRUD (Create, Read, Update, Delete) pada Produk.

## 🏗 Arsitektur & Pola Desain

Aplikasi ini menerapkan arsitektur **MVC** yang bersih untuk memisahkan tanggung jawab kode, memudahkan pemeliharaan, dan meningkatkan skalabilitas:

### 1. Model (`lib/models`)
Lapisan ini mendefinisikan struktur data aplikasi.
*   **Fungsi Utama**: Merepresentasikan objek data seperti `User` dan `Product`.
*   **Serialisasi**: Menangani konversi data JSON dari API menjadi objek Dart (`fromJson`) dan sebaliknya (`toJson`).
*   **Keamanan Data**: Dilengkapi dengan pengecekan *null-safety* dan nilai default (misal: "No Name") untuk mencegah aplikasi *crash* jika data dari server tidak lengkap.

### 2. View (`lib/views`)
Lapisan antarmuka pengguna (UI) yang menampilkan data dan menangkap interaksi pengguna.
*   **Struktur Folder**: Dikelompokkan berdasarkan fitur (`auth`, `products`, `profile`, `splash`).
*   **Reaktivitas**: Menggunakan widget `Consumer` dari Provider untuk mendengarkan perubahan data dari Controller dan memperbarui tampilan secara otomatis tanpa perlu `setState` manual yang berlebihan.

### 3. Controller (`lib/controllers`)
Lapisan logika bisnis yang menjembatani View dan Model.
*   **Peran**: Bertindak sebagai "otak" aplikasi.
*   **Manajemen State**: Meng-extend `ChangeNotifier` untuk memberi tahu View ketika ada perubahan data (misal: *loading* selesai, data produk berhasil diambil).
*   **Komponen Utama**:
    *   **`AuthController`**: Mengelola status login, registrasi, logout, dan penyimpanan sesi pengguna.
    *   **`ProductController`**: Mengelola pengambilan daftar produk, penambahan, pengeditan, dan penghapusan produk.

### 4. Service (`lib/services`)
Lapisan khusus untuk komunikasi dengan pihak luar (API/Backend).
*   **`ApiService`**: Wrapper tunggal (*singleton*) untuk library **Dio**.
*   **Interceptors**: Fitur canggih yang secara otomatis menyisipkan **Bearer Token** dari penyimpanan lokal ke dalam *header* setiap permintaan (request) API. Ini memastikan setiap request terotentikasi tanpa perlu menambahkan token manual berulang kali.

---

## 🚀 Alur & Fitur Aplikasi

### 1. Layar Pembuka & Login Otomatis (`SplashScreen`)
*   **Inisialisasi**: Saat aplikasi dibuka, sistem memeriksa `SharedPreferences` untuk melihat apakah ada token yang tersimpan.
*   **Validasi Sesi**: 
    *   Jika token ditemukan, aplikasi melakukan request ke API `/user` untuk memastikan token masih valid.
    *   **Valid**: Pengguna langsung diarahkan ke Halaman Produk (`ProductListScreen`).
    *   **Tidak Valid/Kadaluarsa**: Pengguna diarahkan kembali ke Halaman Login.

### 2. Otentikasi (`LoginScreen` & `RegisterScreen`)
*   **Login**: Pengguna masuk menggunakan email dan password. Jika berhasil, token JWT disimpan di memori lokal HP.
*   **Register**: Pendaftaran pengguna baru.
*   **Logout**: Menghapus token dari memori dan mengembalikan pengguna ke halaman login.

### 3. Manajemen Produk (`ProductListScreen`)
*   **Daftar Produk**: Menampilkan semua produk yang diambil dari API (`GET /products`)..
*   **Format Mata Uang**: Harga produk ditampilkan dalam format **Rupiah (IDR)** menggunakan utilitas `AppFormatters`.
*   **Interaksi Pengguna**:
    *   **Refresh**: Tarik layar ke bawah (*pull-to-refresh*) untuk memperbarui data.
    *   **Tambah**: Tombol melayang (*FAB*) untuk menambah produk baru.
    *   **Edit/Hapus**: Menu opsi pada setiap kartu produk untuk mengubah atau menghapus item.

### 4. Form Produk (`ProductFormScreen`)
*   **Efisiensi**: Satu halaman formulir digunakan untuk dua fungsi sekaligus (Tambah & Edit).
*   **Logika**:
    *   Jika membuka form dengan membawa data produk, mode berubah menjadi **Edit** (Form terisi otomatis).
    *   Jika membuka form tanpa data, mode menjadi **Tambah** (Form kosong).

### 5. Profil Pengguna (`ProfileScreen`)
*   Menampilkan informasi akun yang sedang login (Nama dan Email).
*   Menyediakan tombol Logout yang aman dengan dialog konfirmasi.

---

## 🔌 Detail Integrasi API (Dio Service)

Logika inti pada `lib/services/api_service.dart` dirancang untuk keamanan dan kemudahan pengembangan:

```dart
// 1. Konfigurasi Dasar
BaseOptions(
  baseUrl: AppConstants.baseUrl, // Dikonfigurasi untuk Emulator (10.0.2.2) atau Device Fisik
  connectTimeout: const Duration(seconds: 10), // Batas waktu koneksi
  receiveTimeout: const Duration(seconds: 10), // Batas waktu respon
);

// 2. Logika Interceptor (Otomatisasi Token)
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Sebelum request dikirim, ambil token dari penyimpanan lokal
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      
      // Jika token ada, sisipkan ke Header Authorization
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    // Penanganan Error Global
    onError: (DioException e, handler) {
      print("API Error: ${e.message}");
      return handler.next(e); // Teruskan error ke UI untuk ditampilkan
    },
  ),
);
```

### Penanganan Respon yang Aman
Aplikasi menangani respon API dengan hati-hati untuk menghindari error tipe data:
*   **Validasi Format**: Memastikan data yang diterima adalah `Map` atau `List` sebelum diproses.
*   **Wrapper Data**: Menangani standar respon Laravel yang sering membungkus data dalam properti `data`.

## 🛠 Teknologi yang Digunakan

*   **Flutter SDK**: Framework UI utama.
*   **Provider**: Manajemen State (Dependency Injection).
*   **Dio**: HTTP Client (Networking & Interceptors).
*   **Shared Preferences**: Penyimpanan Lokal (Persistensi Token).
*   **Intl**: Format Angka dan Mata Uang.

## 📱 Cara Menjalankan

1.  **Konfigurasi URL API**:
    *   Buka file `lib/utils/constants.dart`.
    *   Untuk Android Emulator: Gunakan `http://10.0.2.2:8000/api`
    *   Untuk iOS Simulator: Gunakan `http://127.0.0.1:8000/api`
    *   Untuk Perangkat Fisik: Gunakan IP LAN komputer Anda (contoh: `http://192.168.1.x:8000/api`).

2.  **Instal Dependensi**:
    ```bash
    flutter pub get
    ```

3.  **Jalankan Aplikasi**:
    ```bash
    flutter run
    ```
