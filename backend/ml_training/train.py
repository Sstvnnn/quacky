import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

from data_loader import load_dataset

def build_model(input_shape=(100, 3)):
    """
    Builds a lightweight 1D Convolutional Neural Network (CNN) optimized
    for mobile/on-device inference.
    """
    model = models.Sequential([
        layers.Conv1D(filters=16, kernel_size=5, activation='relu', input_shape=input_shape),
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

    return model

def main():
    print("TensorFlow Version:", tf.__version__)

    print("\n[1/4] Generating/Loading dataset...")
    X, y = load_dataset(num_samples=5000, sampling_rate=50, duration=2.0)

    X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.3, random_state=42)
    X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, random_state=42)

    print(f"Training shape:   X: {X_train.shape}, y: {y_train.shape}")
    print(f"Validation shape: X: {X_val.shape}, y: {y_val.shape}")
    print(f"Testing shape:    X: {X_test.shape}, y: {y_test.shape}")

    print("\n[2/4] Instantiating 1D-CNN Model...")
    model = build_model(input_shape=(100, 3))
    model.summary()

    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
    )

    print("\n[3/4] Starting training loop...")
    os.makedirs('models', exist_ok=True)

    early_stopping = callbacks.EarlyStopping(
        monitor='val_loss',
        patience=8,
        restore_best_weights=True
    )

    model_checkpoint = callbacks.ModelCheckpoint(
        filepath='models/best_model.h5',
        monitor='val_loss',
        save_best_only=True
    )

    history = model.fit(
        X_train, y_train,
        epochs=40,
        batch_size=64,
        validation_data=(X_val, y_val),
        callbacks=[early_stopping, model_checkpoint]
    )

    print("\n[4/4] Evaluating model performance...")
    test_loss, test_acc, test_prec, test_rec = model.evaluate(X_test, y_test)
    print(f"\n--- TEST METRICS ---")
    print(f"Loss:      {test_loss:.4f}")
    print(f"Accuracy:  {test_acc * 100:.2f}%")
    print(f"Precision: {test_prec:.4f}")
    print(f"Recall:    {test_rec:.4f}")

    plt.figure(figsize=(12, 4))

    plt.subplot(1, 2, 1)
    plt.plot(history.history['accuracy'], label='train')
    plt.plot(history.history['val_accuracy'], label='val')
    plt.title('Model Accuracy')
    plt.ylabel('Accuracy')
    plt.xlabel('Epoch')
    plt.legend()

    plt.subplot(1, 2, 2)
    plt.plot(history.history['loss'], label='train')
    plt.plot(history.history['val_loss'], label='val')
    plt.title('Model Loss')
    plt.ylabel('Loss')
    plt.xlabel('Epoch')
    plt.legend()

    plt.tight_layout()
    os.makedirs('plots', exist_ok=True)
    plt.savefig('plots/training_metrics.png')
    print("Saved evaluation charts to 'plots/training_metrics.png'")

    model.save('models/final_earthquake_model.h5')
    print("Saved final Keras model to 'models/final_earthquake_model.h5'")

if __name__ == '__main__':
    main()
