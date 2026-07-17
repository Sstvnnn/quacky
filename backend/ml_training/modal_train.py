import os
import modal

app = modal.App("quacky-ml")

image = (
    modal.Image.debian_slim()
    .pip_install(
        "tensorflow>=2.10.0",
        "scikit-learn",
        "scipy",
        "numpy",
        "matplotlib"
    )
)

@app.function(image=image, timeout=1200)
def train_and_convert_model() -> bytes:
    import numpy as np
    import tensorflow as tf
    from tensorflow.keras import layers, models
    from sklearn.model_selection import train_test_split

    def generate_synthetic_earthquake(sampling_rate=50, duration=2.0):
        n_samples = int(sampling_rate * duration)
        t = np.linspace(0, duration, n_samples)
        freq = np.random.uniform(2.0, 10.0)

        onset_idx = int(n_samples * np.random.uniform(0.1, 0.3))
        envelope = np.zeros(n_samples)
        envelope[onset_idx:] = np.exp(-1.5 * (t[onset_idx:] - t[onset_idx]))

        phase_x = np.random.uniform(0, 2 * np.pi)
        phase_y = np.random.uniform(0, 2 * np.pi)
        phase_z = np.random.uniform(0, 2 * np.pi)

        x = envelope * np.sin(2 * np.pi * freq * t + phase_x)
        y = envelope * np.sin(2 * np.pi * freq * t + phase_y)
        z = envelope * np.sin(2 * np.pi * freq * t + phase_z)

        x += np.random.normal(0, 0.05, n_samples)
        y += np.random.normal(0, 0.05, n_samples)
        z += np.random.normal(0, 0.05, n_samples)

        return np.stack([x, y, z], axis=-1)

    def generate_synthetic_noise(sampling_rate=50, duration=2.0):
        n_samples = int(sampling_rate * duration)
        t = np.linspace(0, duration, n_samples)
        noise_type = np.random.choice(['walking', 'phone_drop', 'stationary'])

        x, y, z = np.zeros(n_samples), np.zeros(n_samples), np.zeros(n_samples)

        if noise_type == 'walking':
            freq = np.random.uniform(1.5, 2.0)
            z = 0.5 * np.sin(2 * np.pi * freq * t) + np.random.normal(0, 0.1, n_samples)
            x = 0.2 * np.sin(2 * np.pi * freq * t + np.pi/2) + np.random.normal(0, 0.05, n_samples)
            y = np.random.normal(0, 0.05, n_samples)
        elif noise_type == 'phone_drop':
            drop_idx = int(n_samples * np.random.uniform(0.3, 0.6))
            spike_len = int(sampling_rate * 0.1)
            x[drop_idx:drop_idx+spike_len] = np.random.uniform(2.0, 4.0) * np.sin(np.linspace(0, np.pi, spike_len))
            y[drop_idx:drop_idx+spike_len] = np.random.uniform(2.0, 4.0) * np.sin(np.linspace(0, np.pi, spike_len))
            z[drop_idx:drop_idx+spike_len] = np.random.uniform(2.0, 4.0) * np.sin(np.linspace(0, np.pi, spike_len))
            x += np.random.normal(0, 0.02, n_samples)
            y += np.random.normal(0, 0.02, n_samples)
            z += np.random.normal(0, 0.02, n_samples)
        else:
            x = np.random.normal(0, 0.01, n_samples)
            y = np.random.normal(0, 0.01, n_samples)
            z = np.random.normal(0, 0.01, n_samples)

        return np.stack([x, y, z], axis=-1)

    def load_dataset(num_samples=5000, sampling_rate=50, duration=2.0):
        X, y = [], []
        half_samples = num_samples // 2
        for _ in range(half_samples):
            X.append(generate_synthetic_earthquake(sampling_rate, duration))
            y.append(1)
        for _ in range(num_samples - half_samples):
            X.append(generate_synthetic_noise(sampling_rate, duration))
            y.append(0)
        X = np.array(X, dtype=np.float32)
        y = np.array(y, dtype=np.float32)
        indices = np.arange(num_samples)
        np.random.shuffle(indices)
        return X[indices], y[indices]

    print("Generating training dataset...")
    X, y = load_dataset(num_samples=5000)
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

    print("Building 1D-CNN architecture...")
    model = models.Sequential([
        layers.Conv1D(filters=16, kernel_size=5, activation='relu', input_shape=(100, 3)),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.Dropout(0.2),

        layers.Conv1D(filters=32, kernel_size=3, activation='relu'),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.Dropout(0.2),

        layers.Flatten(),
        layers.Dense(32, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(1, activation='sigmoid')
    ])

    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )

    print("Starting training loop in the cloud...")
    model.fit(
        X_train, y_train,
        epochs=30,
        batch_size=64,
        validation_data=(X_val, y_val),
        verbose=1
    )

    print("Quantizing and converting model to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    print("Returning serialized TFLite model data...")
    return tflite_model

@app.local_entrypoint()
def main():
    print("⚡ Starting remote training job on Modal...")

    tflite_bytes = train_and_convert_model.remote()

    output_dir = "../../assets"
    os.makedirs(output_dir, exist_ok=True)
    tflite_path = os.path.join(output_dir, "earthquake_classifier.tflite")

    print(f"Saving compiled model to: {tflite_path}...")
    with open(tflite_path, "wb") as f:
        f.write(tflite_bytes)

    print(f"\n✅ SUCCESS! TFLite model generated and saved locally ({len(tflite_bytes)/1024:.2f} KB).")
