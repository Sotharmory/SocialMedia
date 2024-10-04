import json
import requests
from io import BytesIO
from os import listdir, makedirs, remove
from os.path import isfile, join, exists, abspath, isdir
import numpy as np
import tensorflow as tf
import cv2
import tempfile
import shutil

# TensorFlow/Keras imports
version_fn = getattr(tf.keras, "version", None)
if version_fn and version_fn().startswith("3."):
    import tf_keras as keras
else:
    import tensorflow.keras as keras

import tensorflow_hub as hub
from PIL import Image

IMAGE_DIM = 224  # Required/default image dimensionality

def download_file(url, dest_folder):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        filename = url.split('/')[-1]
        file_path = join(dest_folder, filename)
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    f.write(chunk)
        return file_path
    else:
        raise ValueError(f"Failed to download file from URL: {url}")

def load_images(image_paths, image_size, verbose=True):
    '''
    Load images into numpy arrays for passing to model.predict
    '''
    loaded_images = []
    loaded_image_paths = []

    if isinstance(image_paths, str):
        image_paths = [image_paths]

    for img_path in image_paths:
        if isdir(img_path):
            parent = abspath(img_path)
            img_paths = [join(parent, f) for f in listdir(parent) if isfile(join(parent, f))]
        elif isfile(img_path):
            if img_path.lower().endswith(('.mp4', '.avi', '.mov')):
                images, paths = load_video(img_path, image_size)
                return images, paths
            else:
                img_paths = [img_path]
        elif img_path.startswith('http'):
            if img_path.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.gif')):
                img_paths = [img_path]
            elif img_path.lower().endswith(('.mp4', '.avi', '.mov')):
                temp_dir = tempfile.mkdtemp()
                try:
                    video_path = download_file(img_path, temp_dir)
                    images, paths = load_video(video_path, image_size)
                finally:
                    shutil.rmtree(temp_dir)
                return images, paths
            else:
                print(f"Skipping non-image/video URL: {img_path}")
                return np.asarray([]), []
        else:
            print(f"Skipping unknown path type: {img_path}")
            continue

        for img_path in img_paths:
            try:
                if img_path.startswith('http'):
                    response = requests.get(img_path)
                    img = Image.open(BytesIO(response.content))
                else:
                    img = Image.open(img_path)

                if img.mode == 'RGBA':
                    img = img.convert('RGB')

                img = img.resize(image_size)
                img_array = keras.preprocessing.image.img_to_array(img)
                img_array /= 255.0

                loaded_images.append(img_array)
                loaded_image_paths.append(img_path)

                if verbose:
                    print(f"Loaded and resized image: {img_path} to size: {image_size}")

            except Exception as ex:
                print(f"Image Load Failure: {img_path} with exception: {ex}")

    return np.asarray(loaded_images), loaded_image_paths

def load_video(video_path, image_size):
    '''
    Load frames from a video into numpy arrays for passing to model.predict
    '''
    loaded_images = []
    frame_paths = []

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError(f"Error opening video file: {video_path}")

    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame = cv2.resize(frame, image_size)
        frame_array = frame.astype('float32') / 255.0

        loaded_images.append(frame_array)
        frame_paths.append(f"{video_path}_frame{frame_count}")

        frame_count += 1

    cap.release()

    if len(loaded_images) == 0:
        raise ValueError(f"No frames extracted from video file: {video_path}")

    return np.asarray(loaded_images), frame_paths

def load_model_custom(model_path):
    if model_path is None or not exists(model_path):
        raise ValueError(f"Model path must be a valid path to a saved model. Provided path: {model_path}")

    try:
        model = keras.models.load_model(model_path, custom_objects={'KerasLayer': hub.KerasLayer})
        print(model.summary())
    except Exception as e:
        print(f"Error loading model: {e}")
        raise e

    return model

def classify(model, input_paths, image_dim=IMAGE_DIM):
    """ Classify given a model, input paths (could be single string or list), and image dimensionality."""
    if isinstance(input_paths, str):
        if input_paths.lower().endswith(('.mp4', '.avi', '.mov')):
            images, _ = load_video(input_paths, (image_dim, image_dim))
            if len(images) == 0:
                return "No frames extracted from video"
            probs = classify_nd(model, images)
            num_frames = len(images)
            num_dangerous_frames = sum(1 for p in probs if p['result'] == 'Content not safe')
            ratio = num_dangerous_frames / num_frames if num_frames > 0 else 0
            result = 'Content not safe' if ratio > 0.2 else 'Content safe'
            return result
        else:
            images, image_paths = load_images(input_paths, (image_dim, image_dim))
            if len(images) == 0:
                return "No images to classify."
            probs = classify_nd(model, images)
            return probs[0]['result']
    else:
        images, image_paths = load_images(input_paths, (image_dim, image_dim))
        if len(images) == 0:
            return "No images to classify."
        probs = classify_nd(model, images)
        results = {path: prob['result'] for path, prob in zip(image_paths, probs)}
        return results

def classify_nd(model, nd_images):
    """ Classify given a model, image array (numpy)."""
    model_preds = model.predict(nd_images)

    categories = ['drawings', 'hentai', 'neutral', 'porn', 'sexy']
    dangerous_categories = ['hentai', 'porn']
    threshold = 0.2

    results = []
    for single_preds in model_preds:
        single_probs = {categories[i]: float(pred) for i, pred in enumerate(single_preds)}

        combined_probability = sum(single_probs[cat] for cat in dangerous_categories)
        result = 'Content not safe' if combined_probability > threshold else 'Content safe'

        results.append({
            'probabilities': single_probs,
            'result': result
        })
    return results

def main():
    input_path = "https://v5.sex30s.com/wp-content/uploads/2021/09/em-nu-sinh-lang-loan-a-co-nguoi-yeu.jpg"  # Update this URL or path to your image or video
    model_path = "Nudity-Detection-Model.h5"  # Update this path to your model

    # Load model
    model = load_model_custom(model_path)

    # Classify image or video
    result = classify(model, input_path, IMAGE_DIM)

    # Print results
    print(result, '\n')

if __name__ == "__main__":
    main()
