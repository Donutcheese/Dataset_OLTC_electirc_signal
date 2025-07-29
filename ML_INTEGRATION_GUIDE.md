# Machine Learning Integration Guide for OLTC Dataset

## Overview
This guide provides comprehensive examples for integrating OLTC simulation datasets with various machine learning frameworks and models for fault diagnosis.

## Table of Contents
1. [Data Preparation](#data-preparation)
2. [Classification Models](#classification-models)
3. [Deep Learning Models](#deep-learning-models)
4. [Time Series Analysis](#time-series-analysis)
5. [Model Evaluation](#model-evaluation)
6. [Production Deployment](#production-deployment)

## Data Preparation

### Loading and Preprocessing (Python)
```python
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

def load_oltc_data():
    """Load all OLTC datasets and create labels"""
    # Load normal operation data
    normal_current = np.loadtxt('sample_dataset/normal_Iin.csv', delimiter=',')
    normal_voltage = np.loadtxt('sample_dataset/normal_Uout.csv', delimiter=',')
    
    # Load ut3 delay fault data
    ut3_current = np.loadtxt('sample_dataset/ut3delay_Iin.csv', delimiter=',')
    ut3_voltage = np.loadtxt('sample_dataset/ut3delay_Uout.csv', delimiter=',')
    
    # Load ut4-6 delay fault data
    ut456_current = np.loadtxt('sample_dataset/ut4-6delay_Iin.csv', delimiter=',')
    ut456_voltage = np.loadtxt('sample_dataset/ut4-6delay_Uout.csv', delimiter=',')
    
    # Combine features (current and voltage)
    normal_data = np.stack([normal_current, normal_voltage], axis=2)
    ut3_data = np.stack([ut3_current, ut3_voltage], axis=2)
    ut456_data = np.stack([ut456_current, ut456_voltage], axis=2)
    
    # Transpose to (samples, timesteps, features)
    normal_data = np.transpose(normal_data, (1, 0, 2))
    ut3_data = np.transpose(ut3_data, (1, 0, 2))
    ut456_data = np.transpose(ut456_data, (1, 0, 2))
    
    # Create labels: 0=normal, 1=ut3_delay, 2=ut456_delay
    normal_labels = np.zeros(normal_data.shape[0])
    ut3_labels = np.ones(ut3_data.shape[0])
    ut456_labels = np.full(ut456_data.shape[0], 2)
    
    # Combine all data
    X = np.vstack([normal_data, ut3_data, ut456_data])
    y = np.hstack([normal_labels, ut3_labels, ut456_labels])
    
    return X, y

# Load data
X, y = load_oltc_data()
print(f"Data shape: {X.shape}")  # (150, 1001, 2)
print(f"Labels shape: {y.shape}")  # (150,)

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

### Feature Engineering
```python
def extract_features(X):
    """Extract statistical features from time series data"""
    n_samples = X.shape[0]
    features = []
    
    for i in range(n_samples):
        sample_features = []
        
        # For each signal (current and voltage)
        for j in range(X.shape[2]):
            signal = X[i, :, j]
            
            # Time domain features
            sample_features.extend([
                np.mean(signal),
                np.std(signal),
                np.max(signal),
                np.min(signal),
                np.ptp(signal),  # Peak-to-peak
                np.median(signal),
                np.percentile(signal, 25),
                np.percentile(signal, 75),
                np.sqrt(np.mean(signal**2)),  # RMS
            ])
            
            # Frequency domain features (simple)
            fft_vals = np.fft.fft(signal)
            fft_magnitude = np.abs(fft_vals[:len(fft_vals)//2])
            sample_features.extend([
                np.max(fft_magnitude),
                np.argmax(fft_magnitude),  # Dominant frequency
                np.sum(fft_magnitude[:10]),  # Low frequency energy
            ])
        
        features.append(sample_features)
    
    return np.array(features)

# Extract features
X_features = extract_features(X_train)
X_test_features = extract_features(X_test)

# Normalize features
scaler = StandardScaler()
X_features_scaled = scaler.fit_transform(X_features)
X_test_features_scaled = scaler.transform(X_test_features)
```

## Classification Models

### Random Forest Classifier
```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# Train Random Forest
rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=42,
    n_jobs=-1
)
rf_model.fit(X_features_scaled, y_train)

# Predictions
y_pred = rf_model.predict(X_test_features_scaled)

# Evaluation
print("Classification Report:")
print(classification_report(y_test, y_pred, 
                          target_names=['Normal', 'UT3 Delay', 'UT4-6 Delay']))

# Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=['Normal', 'UT3 Delay', 'UT4-6 Delay'],
            yticklabels=['Normal', 'UT3 Delay', 'UT4-6 Delay'])
plt.title('Confusion Matrix - Random Forest')
plt.ylabel('True Label')
plt.xlabel('Predicted Label')
plt.show()

# Feature Importance
feature_names = []
for signal in ['Current', 'Voltage']:
    feature_names.extend([
        f'{signal}_mean', f'{signal}_std', f'{signal}_max', 
        f'{signal}_min', f'{signal}_ptp', f'{signal}_median',
        f'{signal}_q1', f'{signal}_q3', f'{signal}_rms',
        f'{signal}_fft_max', f'{signal}_dom_freq', f'{signal}_low_energy'
    ])

importances = rf_model.feature_importances_
indices = np.argsort(importances)[::-1][:10]

plt.figure(figsize=(10, 6))
plt.bar(range(10), importances[indices])
plt.xticks(range(10), [feature_names[i] for i in indices], rotation=45)
plt.title('Top 10 Feature Importances')
plt.tight_layout()
plt.show()
```

### Support Vector Machine
```python
from sklearn.svm import SVC
from sklearn.model_selection import GridSearchCV

# SVM with Grid Search
param_grid = {
    'C': [0.1, 1, 10, 100],
    'gamma': ['scale', 'auto', 0.001, 0.01],
    'kernel': ['rbf', 'poly']
}

svm_model = SVC(random_state=42)
grid_search = GridSearchCV(svm_model, param_grid, cv=5, n_jobs=-1, verbose=1)
grid_search.fit(X_features_scaled, y_train)

print(f"Best parameters: {grid_search.best_params_}")
print(f"Best CV score: {grid_search.best_score_:.3f}")

# Evaluate best model
best_svm = grid_search.best_estimator_
y_pred_svm = best_svm.predict(X_test_features_scaled)
print("\nSVM Classification Report:")
print(classification_report(y_test, y_pred_svm,
                          target_names=['Normal', 'UT3 Delay', 'UT4-6 Delay']))
```

## Deep Learning Models

### 1D CNN for Time Series Classification
```python
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.utils import to_categorical

# Prepare data for deep learning
y_train_cat = to_categorical(y_train, num_classes=3)
y_test_cat = to_categorical(y_test, num_classes=3)

def create_1d_cnn(input_shape):
    """Create 1D CNN model for time series classification"""
    model = models.Sequential([
        # First Conv Block
        layers.Conv1D(64, kernel_size=7, activation='relu', 
                     input_shape=input_shape),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.Dropout(0.2),
        
        # Second Conv Block
        layers.Conv1D(128, kernel_size=5, activation='relu'),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.Dropout(0.2),
        
        # Third Conv Block
        layers.Conv1D(256, kernel_size=3, activation='relu'),
        layers.BatchNormalization(),
        layers.GlobalAveragePooling1D(),
        layers.Dropout(0.3),
        
        # Dense layers
        layers.Dense(128, activation='relu'),
        layers.Dropout(0.4),
        layers.Dense(3, activation='softmax')
    ])
    
    return model

# Create and compile model
cnn_model = create_1d_cnn((1001, 2))
cnn_model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

cnn_model.summary()

# Train model
history = cnn_model.fit(
    X_train, y_train_cat,
    epochs=50,
    batch_size=16,
    validation_split=0.2,
    callbacks=[
        tf.keras.callbacks.EarlyStopping(patience=10, restore_best_weights=True),
        tf.keras.callbacks.ReduceLROnPlateau(patience=5, factor=0.5)
    ]
)

# Evaluate
test_loss, test_acc = cnn_model.evaluate(X_test, y_test_cat)
print(f"Test accuracy: {test_acc:.3f}")

# Plot training history
plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(history.history['loss'], label='Train Loss')
plt.plot(history.history['val_loss'], label='Val Loss')
plt.title('Model Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()

plt.subplot(1, 2, 2)
plt.plot(history.history['accuracy'], label='Train Accuracy')
plt.plot(history.history['val_accuracy'], label='Val Accuracy')
plt.title('Model Accuracy')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.tight_layout()
plt.show()
```

### LSTM Model
```python
def create_lstm_model(input_shape):
    """Create LSTM model for sequence classification"""
    model = models.Sequential([
        layers.LSTM(128, return_sequences=True, input_shape=input_shape),
        layers.Dropout(0.2),
        layers.LSTM(64, return_sequences=True),
        layers.Dropout(0.2),
        layers.LSTM(32),
        layers.Dropout(0.3),
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.4),
        layers.Dense(3, activation='softmax')
    ])
    
    return model

# Create and train LSTM
lstm_model = create_lstm_model((1001, 2))
lstm_model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Train with reduced sequence length for efficiency
X_train_reduced = X_train[:, ::10, :]  # Sample every 10th point
X_test_reduced = X_test[:, ::10, :]

lstm_history = lstm_model.fit(
    X_train_reduced, y_train_cat,
    epochs=30,
    batch_size=16,
    validation_split=0.2,
    callbacks=[
        tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True)
    ]
)
```

### Transformer-based Model
```python
def create_transformer_model(input_shape, num_heads=4, ff_dim=128):
    """Create a simplified Transformer model"""
    inputs = layers.Input(shape=input_shape)
    
    # Positional encoding
    positions = tf.range(start=0, limit=input_shape[0], delta=1)
    position_embedding = layers.Embedding(
        input_dim=input_shape[0], output_dim=input_shape[1]
    )(positions)
    x = inputs + position_embedding
    
    # Multi-head attention
    attention_output = layers.MultiHeadAttention(
        num_heads=num_heads, key_dim=input_shape[1]
    )(x, x)
    attention_output = layers.Dropout(0.1)(attention_output)
    x = layers.LayerNormalization(epsilon=1e-6)(x + attention_output)
    
    # Feed forward
    ff_output = layers.Dense(ff_dim, activation="relu")(x)
    ff_output = layers.Dense(input_shape[1])(ff_output)
    ff_output = layers.Dropout(0.1)(ff_output)
    x = layers.LayerNormalization(epsilon=1e-6)(x + ff_output)
    
    # Global pooling and classification
    x = layers.GlobalAveragePooling1D()(x)
    x = layers.Dense(64, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(3, activation="softmax")(x)
    
    model = models.Model(inputs=inputs, outputs=outputs)
    return model

# Create and train Transformer
transformer_model = create_transformer_model((1001, 2))
transformer_model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)
```

## Time Series Analysis

### Anomaly Detection with Autoencoder
```python
def create_autoencoder(input_shape):
    """Create autoencoder for anomaly detection"""
    # Encoder
    encoder_input = layers.Input(shape=input_shape)
    x = layers.Conv1D(32, 3, activation='relu', padding='same')(encoder_input)
    x = layers.MaxPooling1D(2, padding='same')(x)
    x = layers.Conv1D(16, 3, activation='relu', padding='same')(x)
    x = layers.MaxPooling1D(2, padding='same')(x)
    x = layers.Conv1D(8, 3, activation='relu', padding='same')(x)
    encoded = layers.MaxPooling1D(2, padding='same')(x)
    
    # Decoder
    x = layers.Conv1D(8, 3, activation='relu', padding='same')(encoded)
    x = layers.UpSampling1D(2)(x)
    x = layers.Conv1D(16, 3, activation='relu', padding='same')(x)
    x = layers.UpSampling1D(2)(x)
    x = layers.Conv1D(32, 3, activation='relu', padding='same')(x)
    x = layers.UpSampling1D(2)(x)
    decoded = layers.Conv1D(2, 3, activation='linear', padding='same')(x)
    
    autoencoder = models.Model(encoder_input, decoded)
    return autoencoder

# Train autoencoder on normal data only
X_normal = X[y == 0]
X_train_normal, X_val_normal = train_test_split(X_normal, test_size=0.2, random_state=42)

autoencoder = create_autoencoder((1001, 2))
autoencoder.compile(optimizer='adam', loss='mse')

# Adjust input shape to match encoder output
def adjust_shape(x, target_length=1000):
    """Adjust shape to match decoder output"""
    return x[:, :target_length, :]

X_train_adjusted = adjust_shape(X_train_normal)
X_val_adjusted = adjust_shape(X_val_normal)

autoencoder.fit(
    X_train_adjusted, X_train_adjusted,
    epochs=50,
    batch_size=8,
    validation_data=(X_val_adjusted, X_val_adjusted)
)

# Use for anomaly detection
def detect_anomalies(autoencoder, X, threshold_percentile=95):
    """Detect anomalies based on reconstruction error"""
    X_adjusted = adjust_shape(X)
    X_reconstructed = autoencoder.predict(X_adjusted)
    
    # Calculate reconstruction error
    mse = np.mean((X_adjusted - X_reconstructed) ** 2, axis=(1, 2))
    
    # Set threshold based on normal data
    threshold = np.percentile(mse[y == 0], threshold_percentile)
    
    # Classify as anomaly if error > threshold
    anomalies = mse > threshold
    
    return anomalies, mse, threshold

# Detect anomalies
anomalies, errors, threshold = detect_anomalies(autoencoder, X)

# Visualize results
plt.figure(figsize=(10, 6))
for i, (label, name) in enumerate([(0, 'Normal'), (1, 'UT3 Delay'), (2, 'UT4-6 Delay')]):
    mask = y == label
    plt.scatter(np.where(mask)[0], errors[mask], label=name, alpha=0.6)

plt.axhline(y=threshold, color='red', linestyle='--', label='Threshold')
plt.xlabel('Sample Index')
plt.ylabel('Reconstruction Error')
plt.title('Anomaly Detection Results')
plt.legend()
plt.show()
```

### Statistical Process Control
```python
from scipy import stats

def calculate_control_limits(X_normal, confidence=0.997):
    """Calculate statistical control limits"""
    # Extract features for each time point
    means = np.mean(X_normal, axis=0)
    stds = np.std(X_normal, axis=0)
    
    # Calculate control limits (3-sigma)
    z_score = stats.norm.ppf((1 + confidence) / 2)
    ucl = means + z_score * stds
    lcl = means - z_score * stds
    
    return means, ucl, lcl

# Calculate control limits from normal data
X_normal = X[y == 0]
mean_profile, ucl, lcl = calculate_control_limits(X_normal)

# Check if new sample is within control limits
def check_control_limits(sample, mean_profile, ucl, lcl):
    """Check if sample violates control limits"""
    violations_upper = sample > ucl
    violations_lower = sample < lcl
    total_violations = np.sum(violations_upper) + np.sum(violations_lower)
    
    return total_violations, violations_upper, violations_lower

# Visualize control chart
sample_idx = 75  # Example: a fault sample
sample = X[sample_idx]
violations, v_upper, v_lower = check_control_limits(sample, mean_profile, ucl, lcl)

plt.figure(figsize=(15, 8))
time = np.linspace(0, 0.1, 1001)

# Current signal
plt.subplot(2, 1, 1)
plt.plot(time, sample[:, 0], 'b-', label='Sample Current', alpha=0.7)
plt.plot(time, mean_profile[:, 0], 'g-', label='Mean Profile')
plt.plot(time, ucl[:, 0], 'r--', label='UCL')
plt.plot(time, lcl[:, 0], 'r--', label='LCL')
plt.fill_between(time, lcl[:, 0], ucl[:, 0], alpha=0.2, color='gray')
plt.scatter(time[v_upper[:, 0]], sample[v_upper[:, 0], 0], 
           color='red', s=20, label='Violations')
plt.scatter(time[v_lower[:, 0]], sample[v_lower[:, 0], 0], 
           color='red', s=20)
plt.xlabel('Time (s)')
plt.ylabel('Current (A)')
plt.title(f'Control Chart - Current Signal (Sample {sample_idx}, Label: {int(y[sample_idx])})')
plt.legend()

# Voltage signal
plt.subplot(2, 1, 2)
plt.plot(time, sample[:, 1], 'b-', label='Sample Voltage', alpha=0.7)
plt.plot(time, mean_profile[:, 1], 'g-', label='Mean Profile')
plt.plot(time, ucl[:, 1], 'r--', label='UCL')
plt.plot(time, lcl[:, 1], 'r--', label='LCL')
plt.fill_between(time, lcl[:, 1], ucl[:, 1], alpha=0.2, color='gray')
plt.scatter(time[v_upper[:, 1]], sample[v_upper[:, 1], 1], 
           color='red', s=20, label='Violations')
plt.scatter(time[v_lower[:, 1]], sample[v_lower[:, 1], 1], 
           color='red', s=20)
plt.xlabel('Time (s)')
plt.ylabel('Voltage (V)')
plt.title('Control Chart - Voltage Signal')
plt.legend()

plt.tight_layout()
plt.show()

print(f"Total violations: {violations}")
```

## Model Evaluation

### Cross-Validation and Metrics
```python
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
import joblib

def evaluate_model_cv(model, X, y, cv_folds=5):
    """Comprehensive model evaluation with cross-validation"""
    skf = StratifiedKFold(n_splits=cv_folds, shuffle=True, random_state=42)
    
    metrics = {
        'accuracy': [],
        'precision': [],
        'recall': [],
        'f1': []
    }
    
    for fold, (train_idx, val_idx) in enumerate(skf.split(X, y)):
        X_train_fold = X[train_idx]
        y_train_fold = y[train_idx]
        X_val_fold = X[val_idx]
        y_val_fold = y[val_idx]
        
        # Train model
        model.fit(X_train_fold, y_train_fold)
        
        # Predict
        y_pred = model.predict(X_val_fold)
        
        # Calculate metrics
        acc = accuracy_score(y_val_fold, y_pred)
        prec, rec, f1, _ = precision_recall_fscore_support(
            y_val_fold, y_pred, average='weighted'
        )
        
        metrics['accuracy'].append(acc)
        metrics['precision'].append(prec)
        metrics['recall'].append(rec)
        metrics['f1'].append(f1)
        
        print(f"Fold {fold+1}: Acc={acc:.3f}, F1={f1:.3f}")
    
    # Average metrics
    for metric in metrics:
        mean_val = np.mean(metrics[metric])
        std_val = np.std(metrics[metric])
        print(f"\n{metric.capitalize()}: {mean_val:.3f} (+/- {std_val:.3f})")
    
    return metrics

# Evaluate Random Forest with cross-validation
print("Random Forest Cross-Validation:")
rf_metrics = evaluate_model_cv(
    RandomForestClassifier(n_estimators=100, random_state=42),
    X_features_scaled, y
)
```

### Model Comparison
```python
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.naive_bayes import GaussianNB

def compare_models(X, y):
    """Compare multiple models"""
    models = {
        'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42),
        'SVM': SVC(kernel='rbf', random_state=42),
        'Logistic Regression': LogisticRegression(max_iter=1000, random_state=42),
        'KNN': KNeighborsClassifier(n_neighbors=5),
        'Naive Bayes': GaussianNB()
    }
    
    results = []
    
    for name, model in models.items():
        # Cross-validation scores
        cv_scores = cross_val_score(model, X, y, cv=5, scoring='accuracy')
        
        results.append({
            'Model': name,
            'Mean Accuracy': cv_scores.mean(),
            'Std Accuracy': cv_scores.std(),
            'Min Accuracy': cv_scores.min(),
            'Max Accuracy': cv_scores.max()
        })
        
        print(f"{name}: {cv_scores.mean():.3f} (+/- {cv_scores.std():.3f})")
    
    # Create comparison dataframe
    results_df = pd.DataFrame(results)
    results_df = results_df.sort_values('Mean Accuracy', ascending=False)
    
    # Visualize comparison
    plt.figure(figsize=(10, 6))
    x = range(len(results_df))
    plt.bar(x, results_df['Mean Accuracy'])
    plt.errorbar(x, results_df['Mean Accuracy'], 
                yerr=results_df['Std Accuracy'], 
                fmt='none', color='black', capsize=5)
    plt.xticks(x, results_df['Model'], rotation=45)
    plt.ylabel('Accuracy')
    plt.title('Model Comparison - 5-Fold Cross-Validation')
    plt.ylim(0, 1.1)
    plt.tight_layout()
    plt.show()
    
    return results_df

# Compare models
results_df = compare_models(X_features_scaled, y)
```

## Production Deployment

### Model Serialization and Loading
```python
import pickle
import joblib
from datetime import datetime

def save_model_package(model, scaler, metadata, filename_prefix='oltc_model'):
    """Save complete model package for deployment"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # Create model package
    model_package = {
        'model': model,
        'scaler': scaler,
        'metadata': metadata,
        'timestamp': timestamp,
        'feature_names': metadata.get('feature_names', []),
        'model_type': type(model).__name__,
        'version': '1.0'
    }
    
    # Save with joblib (recommended for scikit-learn models)
    filename = f"{filename_prefix}_{timestamp}.pkl"
    joblib.dump(model_package, filename)
    print(f"Model saved as: {filename}")
    
    return filename

# Save the trained model
metadata = {
    'feature_names': feature_names,
    'n_features': len(feature_names),
    'classes': ['Normal', 'UT3 Delay', 'UT4-6 Delay'],
    'training_samples': len(X_train),
    'test_accuracy': 0.95  # Example
}

saved_model = save_model_package(rf_model, scaler, metadata)
```

### Real-time Prediction Pipeline
```python
class OLTCPredictor:
    """Production-ready OLTC fault predictor"""
    
    def __init__(self, model_path):
        """Load model package"""
        self.model_package = joblib.load(model_path)
        self.model = self.model_package['model']
        self.scaler = self.model_package['scaler']
        self.metadata = self.model_package['metadata']
        
    def preprocess_signal(self, current_signal, voltage_signal):
        """Preprocess raw signals"""
        # Ensure correct shape
        if len(current_signal) != 1001 or len(voltage_signal) != 1001:
            raise ValueError("Signals must have exactly 1001 data points")
        
        # Create feature array
        X = np.array([[current_signal, voltage_signal]])
        X = np.transpose(X, (0, 2, 1))
        
        # Extract features
        features = extract_features(X)
        
        # Scale features
        features_scaled = self.scaler.transform(features)
        
        return features_scaled
    
    def predict(self, current_signal, voltage_signal):
        """Predict fault type with confidence"""
        # Preprocess
        features = self.preprocess_signal(current_signal, voltage_signal)
        
        # Predict
        prediction = self.model.predict(features)[0]
        probabilities = self.model.predict_proba(features)[0]
        
        # Get class name
        class_name = self.metadata['classes'][int(prediction)]
        confidence = probabilities[int(prediction)]
        
        return {
            'prediction': class_name,
            'confidence': confidence,
            'probabilities': {
                self.metadata['classes'][i]: prob 
                for i, prob in enumerate(probabilities)
            }
        }
    
    def batch_predict(self, current_signals, voltage_signals):
        """Predict multiple samples"""
        results = []
        for curr, volt in zip(current_signals, voltage_signals):
            try:
                result = self.predict(curr, volt)
                results.append(result)
            except Exception as e:
                results.append({'error': str(e)})
        return results

# Example usage
predictor = OLTCPredictor(saved_model)

# Simulate real-time data
test_current = X_test[0, :, 0]
test_voltage = X_test[0, :, 1]

result = predictor.predict(test_current, test_voltage)
print(f"Prediction: {result['prediction']}")
print(f"Confidence: {result['confidence']:.2%}")
print(f"All probabilities: {result['probabilities']}")
```

### API Integration Example
```python
from flask import Flask, request, jsonify
import numpy as np

app = Flask(__name__)

# Load model once at startup
predictor = OLTCPredictor('oltc_model_20240101_120000.pkl')

@app.route('/predict', methods=['POST'])
def predict_fault():
    """API endpoint for OLTC fault prediction"""
    try:
        # Get data from request
        data = request.get_json()
        
        # Validate input
        if 'current' not in data or 'voltage' not in data:
            return jsonify({'error': 'Missing current or voltage data'}), 400
        
        current = np.array(data['current'])
        voltage = np.array(data['voltage'])
        
        # Make prediction
        result = predictor.predict(current, voltage)
        
        # Add request metadata
        result['timestamp'] = datetime.now().isoformat()
        result['model_version'] = predictor.metadata['version']
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': predictor is not None,
        'model_version': predictor.metadata.get('version', 'unknown')
    })

# Example client code
def call_prediction_api(current_data, voltage_data, api_url='http://localhost:5000'):
    """Call the prediction API"""
    import requests
    
    payload = {
        'current': current_data.tolist(),
        'voltage': voltage_data.tolist()
    }
    
    response = requests.post(f'{api_url}/predict', json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"API error: {response.status_code} - {response.text}")
```

### Monitoring and Logging
```python
import logging
from datetime import datetime
import json

class ModelMonitor:
    """Monitor model performance in production"""
    
    def __init__(self, log_file='oltc_predictions.log'):
        self.logger = logging.getLogger('OLTCMonitor')
        handler = logging.FileHandler(log_file)
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
        
        self.prediction_history = []
        
    def log_prediction(self, input_data, prediction_result, actual_label=None):
        """Log prediction for monitoring"""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'prediction': prediction_result['prediction'],
            'confidence': prediction_result['confidence'],
            'actual': actual_label,
            'input_stats': {
                'current_mean': float(np.mean(input_data['current'])),
                'current_std': float(np.std(input_data['current'])),
                'voltage_mean': float(np.mean(input_data['voltage'])),
                'voltage_std': float(np.std(input_data['voltage']))
            }
        }
        
        self.prediction_history.append(log_entry)
        self.logger.info(json.dumps(log_entry))
        
    def calculate_drift_metrics(self, window_size=100):
        """Calculate prediction drift metrics"""
        if len(self.prediction_history) < window_size:
            return None
            
        recent_predictions = self.prediction_history[-window_size:]
        
        # Calculate prediction distribution
        prediction_counts = {}
        confidence_scores = []
        
        for entry in recent_predictions:
            pred = entry['prediction']
            prediction_counts[pred] = prediction_counts.get(pred, 0) + 1
            confidence_scores.append(entry['confidence'])
        
        # Calculate metrics
        metrics = {
            'prediction_distribution': {
                k: v/window_size for k, v in prediction_counts.items()
            },
            'mean_confidence': np.mean(confidence_scores),
            'min_confidence': np.min(confidence_scores),
            'low_confidence_ratio': sum(1 for c in confidence_scores if c < 0.7) / window_size
        }
        
        # Check for alerts
        if metrics['mean_confidence'] < 0.75:
            self.logger.warning(f"Low average confidence: {metrics['mean_confidence']:.3f}")
        
        if metrics['low_confidence_ratio'] > 0.2:
            self.logger.warning(f"High ratio of low confidence predictions: {metrics['low_confidence_ratio']:.2%}")
        
        return metrics

# Example usage with monitoring
monitor = ModelMonitor()

# In production prediction loop
for i in range(len(X_test)):
    current = X_test[i, :, 0]
    voltage = X_test[i, :, 1]
    
    # Make prediction
    result = predictor.predict(current, voltage)
    
    # Log prediction
    monitor.log_prediction(
        {'current': current, 'voltage': voltage},
        result,
        actual_label=y_test[i]
    )
    
    # Check drift every 100 predictions
    if (i + 1) % 100 == 0:
        drift_metrics = monitor.calculate_drift_metrics()
        if drift_metrics:
            print(f"Drift metrics at prediction {i+1}:")
            print(f"  Prediction distribution: {drift_metrics['prediction_distribution']}")
            print(f"  Mean confidence: {drift_metrics['mean_confidence']:.3f}")
```

## Best Practices

1. **Data Handling**
   - Always validate input data shape and range
   - Handle missing or corrupted data gracefully
   - Implement proper error handling in production

2. **Model Selection**
   - Start with simple models (Random Forest) as baseline
   - Use cross-validation for reliable performance estimates
   - Consider ensemble methods for production deployment

3. **Feature Engineering**
   - Domain-specific features often outperform raw data
   - Consider both time and frequency domain features
   - Validate feature importance regularly

4. **Production Deployment**
   - Version control models and preprocessing pipelines
   - Implement comprehensive logging and monitoring
   - Set up alerts for prediction drift and low confidence

5. **Performance Optimization**
   - Use batch predictions when possible
   - Consider model quantization for edge deployment
   - Cache preprocessing results for repeated signals

## Conclusion

This guide provides comprehensive examples for integrating OLTC datasets with various machine learning approaches. The code examples cover the complete ML pipeline from data preparation to production deployment, enabling robust fault diagnosis systems for power transformers.