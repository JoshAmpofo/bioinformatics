#!/usr/bin/env python3

import os
import cv2
import numpy as np
import matplotlib.pyplot as plt


# set image sizes
IMG_SIZE = 50

# one-hot encoding
BENIGN = [1, 0]
MALIGNANT = [0, 1]


# file locations
benign_training_data_folder = 'melanoma_cancer_dataset/train/benign/'
malignant_training_data_folder = 'melanoma_cancer_dataset/train/malignant/'

benign_testing_data_folder = 'melanoma_cancer_dataset/test/benign/'
malignant_testing_data_folder = 'melanoma_cancer_dataset/test/malignant/'

benign_train_resized = []
malignant_train_resized = []

benign_test_resized = []
malignant_test_resized = []

# BENIGN TRAINING DATA PROCESSING
# open files for resizing
for filename in os.listdir(benign_training_data_folder):
    try:
        # generate full paths
        path = benign_training_data_folder + filename
        # read each imag
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        
        if img is None:
            print(f"Warning: Could not read image {path}")
            continue
        
        # plt.imshow(img)#, cmap='gray')
        # plt.show()
        # break
        
        # resize images
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img_array = np.array(img)
        # print(img_array)
        # print(img_array.shape)
        # break
        
        # convert to numpy array
        benign_train_resized.append([img_array, np.array(BENIGN)])
    except Exception as e:
        print(f"Error processing {filename}: {e}")

# MALIGNANT TRAINING DATA PROCESSING
# open files for resizing
for filename in os.listdir(malignant_training_data_folder):
    try:
        # generate full paths
        path = malignant_training_data_folder + filename
        # read each imag
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        
        if img is None:
            print(f"Warning: Could not read image {path}")
            continue
        
        # resize images
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img_array = np.array(img)
        
        # convert to numpy array
        malignant_train_resized.append([img_array, np.array(MALIGNANT)])
    except Exception as e:
        print(f"Error processing {filename}: {e}")

# BENIGN TESTING DATA PROCESSING    
# open files for resizing
for filename in os.listdir(benign_testing_data_folder):
    try:
        # generate full paths
        path = benign_testing_data_folder + filename
        # read each imag
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        
        if img is None:
            print(f"Warning: Could not read image {path}")
            continue
            
        # resize images
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img_array = np.array(img)
        
        # convert to numpy array
        benign_test_resized.append([img_array, np.array(BENIGN)])
    except Exception as e:
        print(f"Error processing {filename}: {e}")


# MALIGNANT TESTING DATA PROCESSING
# open files for resizing
for filename in os.listdir(malignant_testing_data_folder):
    try:
        # generate full paths
        path = malignant_testing_data_folder + filename
        # read each imag
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        
        if img is None:
            print(f"Warning: Could not read image {path}")
            continue
            
        # resize images
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img_array = np.array(img)
        
        # convert to numpy array
        malignant_test_resized.append([img_array, np.array(MALIGNANT)])
    except Exception as e:
        print(f"Error processing {filename}: {e}")
    
# resize benign to malignant training data
benign_train_resized = benign_train_resized[:len(malignant_train_resized)]    

# check lengths of data
print()
print()

print(f"Benign training count: {len(benign_train_resized)}")
print(f"Malignant training count: {len(malignant_train_resized)}")
print()
print(f"Benign testing count: {len(benign_test_resized)}")
print(f"Malignant testing count: {len(malignant_test_resized)}")


# merge training data
training_data = benign_train_resized + malignant_train_resized
# shuffle data
np.random.shuffle(training_data)

# separate features and labels for training data
X_train = []
y_train = []
for features, label in training_data:
    X_train.append(features)
    y_train.append(label)

X_train = np.array(X_train)
y_train = np.array(y_train)

# save training data
np.save('melanoma_training_features.npy', X_train)
np.save('melanoma_training_labels.npy', y_train)


# merge testing data
testing_data = benign_test_resized + malignant_test_resized
# shuffle data
np.random.shuffle(testing_data)

# separate features and labels for testing data
X_test = []
y_test = []
for features, label in testing_data:
    X_test.append(features)
    y_test.append(label)

X_test = np.array(X_test)
y_test = np.array(y_test)

# save testing data
np.save('melanoma_testing_features.npy', X_test)
np.save('melanoma_testing_labels.npy', y_test)