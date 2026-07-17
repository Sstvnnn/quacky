import numpy as np
from scipy import signal

def generate_synthetic_earthquake(sampling_rate=50, duration=2.0):
    """
    Generates a synthetic earthquake P-wave / S-wave signal on 3 axes.
    Characteristics: Rhythmic shaking with an envelope decay.
    """
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
    """
    Generates synthetic daily activities (walking, dropping phone, stationary).
    """
    n_samples = int(sampling_rate * duration)
    t = np.linspace(0, duration, n_samples)

    noise_type = np.random.choice(['walking', 'phone_drop', 'stationary'])

    x = np.zeros(n_samples)
    y = np.zeros(n_samples)
    z = np.zeros(n_samples)

    if noise_type == 'walking':
        freq = np.random.uniform(1.5, 2.0)
        z = 0.5 * np.sin(2 * np.pi * freq * t) + np.random.normal(0, 0.1, n_samples)
        x = 0.2 * np.sin(2 * np.pi * freq * t + np.pi/2) + np.random.normal(0, 0.05, n_samples)
        y = 0.1 * np.random.normal(0, 0.05, n_samples)

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

def load_dataset(num_samples=2000, sampling_rate=50, duration=2.0):
    """
    Creates a balanced dataset of synthetic earthquake waveforms and noise signals
    to bootstrap model training.

    Returns:
        X (np.ndarray): Shape (num_samples, samples_per_window, 3)
        y (np.ndarray): Shape (num_samples,) containing binary labels (1=earthquake, 0=noise)
    """
    n_samples_per_window = int(sampling_rate * duration)
    X = []
    y = []

    half_samples = num_samples // 2

    for _ in range(half_samples):
        waveform = generate_synthetic_earthquake(sampling_rate, duration)
        X.append(waveform)
        y.append(1)

    for _ in range(num_samples - half_samples):
        waveform = generate_synthetic_noise(sampling_rate, duration)
        X.append(waveform)
        y.append(0)

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.float32)

    indices = np.arange(num_samples)
    np.random.shuffle(indices)

    return X[indices], y[indices]

if __name__ == '__main__':
    X, y = load_dataset(num_samples=10)
    print(f"Dataset generated. Shape of X: {X.shape}, Shape of y: {y.shape}")
    print(f"First label: {y[0]}")
