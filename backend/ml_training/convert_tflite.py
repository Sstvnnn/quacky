import os
import tensorflow as tf
import numpy as np

def convert_model():
    model_path = 'models/best_model.h5'
    if not os.path.exists(model_path):
        model_path = 'models/final_earthquake_model.h5'

    if not os.path.exists(model_path):
        raise FileNotFoundError("No trained Keras model found in the 'models' directory. Run train.py first.")

    print(f"Loading trained Keras model: {model_path}...")
    model = tf.keras.models.load_model(model_path)

    print("Converting model to TensorFlow Lite format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    output_dir = '../../assets'
    os.makedirs(output_dir, exist_ok=True)
    tflite_path = os.path.join(output_dir, 'earthquake_classifier.tflite')

    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)

    print(f"\n✅ TFLite model successfully exported to: {tflite_path}")
    print(f"Original model size: {os.path.getsize(model_path) / 1024:.2f} KB")
    print(f"TFLite model size:   {os.path.getsize(tflite_path) / 1024:.2f} KB")

    print("\nVerifying model inputs and outputs...")
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print("\n=== Model Details ===")
    print("Input details:")
    print(f"  Shape: {input_details[0]['shape']}")
    print(f"  Type:  {input_details[0]['dtype']}")
    print("Output details:")
    print(f"  Shape: {output_details[0]['shape']}")
    print(f"  Type:  {output_details[0]['dtype']}")
    print("=====================")
    print("\nEverything is ready! Copy the assets folder path to pubspec.yaml if you haven't.")

if __name__ == '__main__':
    convert_model()
