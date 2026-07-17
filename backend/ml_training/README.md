# Quacky ML — On-Device 1D CNN Earthquake Classifier

Modul ini berisi pipeline untuk melatih model klasifikasi gempa bumi menggunakan data sensor accelerometer 3-axis (X, Y, Z) dan mengekspornya ke format TensorFlow Lite (`.tflite`).

---

## ⚡ Cloud Training via Modal (Rekomendasi)

Jika komputer Anda lambat atau berat mendownload library berat seperti TensorFlow secara lokal, Anda dapat menjalankan seluruh pipeline training di cloud menggunakan **Modal** gratis. Model hasil kompilasi akan otomatis terdownload ke komputer lokal Anda setelah selesai.

### Langkah-langkah:

1. **Install library `modal` secara lokal** (sangat cepat & ringan, tidak ada TensorFlow lokal):
   ```bash
   pip install modal
   ```

2. **Login/Authenticate ke Akun Modal Anda:**
   ```bash
   modal setup
   ```

3. **Jalankan Training di Cloud:**
   ```bash
   modal run modal_train.py
   ```
   *   Modal akan secara otomatis menyewa container di server mereka, mendownload TensorFlow di cloud, memproses dataset, melatih model 1D-CNN, mengompresnya dengan dynamic-range quantization, lalu mengirimkan file `.tflite` hasil jadi kembali ke komputer Anda.
   *   Hasil file akan otomatis tersimpan langsung di folder aset Flutter Anda di:
       [quacky/assets/earthquake_classifier.tflite](../../assets/earthquake_classifier.tflite).

---

## 🛠️ Local Training (Alternatif Tradisional)

Jika Anda ingin menjalankan secara lokal sepenuhnya:

1. **Install Dependensi:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Latih Model:**
   ```bash
   python train.py
   ```

3. **Konversi Model ke TFLite:**
   ```bash
   python convert_tflite.py
   ```

---

## 🔬 Penjelasan Teknis Model (1D-CNN)

Model didesain sangat kecil dan hemat daya baterai (battery-friendly) agar bisa dieksekusi setiap kali sensor mendeteksi guncangan awal:

*   **Format Input:** `(100, 3)`. Model memproses window sepanjang 2.0 detik dengan sampling rate 50Hz (100 total time steps), dan 3-axis accelerometer data (X, Y, Z).
*   **Layer 1 (Conv1D + MaxPool):** Mengekstrak pola gelombang frekuensi rendah (seismic wave signature) pada masing-masing axis.
*   **Layer 2 (Conv1D + MaxPool):** Mengekstrak hubungan spasial gabungan multi-axis (gerakan berputar/rhythmic shaking).
*   **Output:** 1 Nilai Dense dengan aktivasi **Sigmoid** [0.0 - 1.0].
    *   Jika output mendekati `1.0`, tandanya model mendeteksi gempa bumi (earthquake).
    *   Jika output mendekati `0.0`, tandanya model menganggap itu noise biasa (jalan kaki, HP terjatuh, dsb).
    *   Threshold rekomendasi aplikasi: **> 0.85 (85% Confidence)** untuk memicu ping ke Supabase.
