# 🚀 Настройка GPU для T-one (CUDA 12.8)

## 📋 Обзор изменений

В проект добавлена поддержка GPU ускорения для ONNX Runtime. Теперь модель может работать на:

- **TensorRT** (самый быстрый, NVIDIA GPU)
- **CUDA** (NVIDIA GPU)
- **DirectML** (Windows GPU)
- **OpenVINO** (Intel GPU/CPU)
- **CPU** (fallback)

## ✅ Текущий статус

✅ **ONNX Runtime GPU установлен**: версия 1.22.0
✅ **CUDA 12.8 поддерживается**
✅ **Провайдеры доступны**: TensorRT, CUDA, CPU
✅ **cuDNN 9.11 настроен**: автоматическая установка через `make setup_cudnn`
✅ **GPU ускорение работает**: без ошибок и предупреждений

## � Быстрый старт

```bash
# 1. Настройте cuDNN (один раз)
make setup_cudnn

# 2. Запустите сервер с GPU
make up_dev          # Компактный режим
make up_dev_full     # Полный режим с KenLM

# Результат: 🚀 Using CUDA GPU acceleration (без ошибок)
```

## �🔧 Настройка GPU

### 1. Для NVIDIA GPU (CUDA 12.8) - ВЫПОЛНЕНО ✅

```bash
# GPU версия уже установлена в pyproject.toml
"onnxruntime-gpu (>=1.19.0)"

# Проверить доступные провайдеры
uv run python -c "import onnxruntime as ort; print('Available providers:', ort.get_available_providers())"
# Результат: ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']
```

### 2. Установка cuDNN 9.x для полной CUDA поддержки

**Требуется для устранения предупреждения о `cudnn64_9.dll`**

1. **Скачайте cuDNN 9.x** с [NVIDIA Developer](https://developer.nvidia.com/cudnn)

   - Выберите версию для CUDA 12.x
   - Требуется регистрация NVIDIA Developer

2. **Установите cuDNN**:

   **Вариант A: Глобальная установка**

   ```bash
   # Распакуйте архив в папку CUDA
   # Обычно: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\
   ```

   **Вариант B: Локальная установка в проект (рекомендуется)**

   ```bash
   # Скопируйте cudnn64_9.dll прямо в проект
   # Из: C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll
   # В: C:\Users\vs\Documents\DEV\streaming-voice\cudnn64_9.dll

   # Или создайте папку libs
   mkdir libs
   copy "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll" libs\

   # Добавьте libs в PATH для проекта
   set PATH=%PATH%;%CD%\libs
   ```

3. **Автоматическая установка через Makefile**:

   ```bash
   # Автоматически найдет и скопирует cuDNN в проект
   make setup_cudnn

   # Затем запустите сервер (PATH будет настроен автоматически)
   make up_dev
   # Должно показать: 🚀 Using CUDA GPU acceleration (без ошибок)
   ```

4. **Проверьте установку**:
   ```bash
   # После установки cuDNN предупреждения исчезнут
   make up_dev
   # Должно показать: 🚀 Using CUDA GPU acceleration (без ошибок)
   ```

### 3. Альтернатива: DirectML (если нет NVIDIA GPU)

```bash
# Для AMD/Intel GPU на Windows
uv remove onnxruntime-gpu
uv add onnxruntime-directml
```

### 3. Переменные окружения

- `TONE_USE_GPU=true` - включить GPU (по умолчанию)
- `TONE_USE_GPU=false` - принудительно использовать CPU
- `ORT_NUM_THREADS=4` - количество CPU потоков

## 🎯 Использование

### Компактный режим (Greedy декодер)

```bash
make up_dev
# Или напрямую:
# TONE_USE_COMPACT=true TONE_USE_GPU=true LOAD_FROM_FOLDER=models uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
```

### Полный режим (BeamSearch + KenLM)

```bash
make up_dev_full
# Или напрямую:
# TONE_USE_COMPACT=false TONE_USE_GPU=true LOAD_FROM_FOLDER=models uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
```

## 📊 Различия между режимами

| Параметр          | `make up_dev` | `make up_dev_full` |
| ----------------- | ------------- | ------------------ |
| **Декодер**       | Greedy        | BeamSearch + KenLM |
| **Размер модели** | ~144MB        | ~5.6GB             |
| **Скорость**      | Быстро        | Медленно           |
| **Точность**      | Хорошая       | Отличная           |
| **Память**        | Мало          | Много              |

## 🔍 Проверка статуса

При запуске вы увидите:

**✅ С GPU поддержкой (текущее состояние):**

```
🚀 Using CUDA GPU acceleration
🔧 ONNX Runtime providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
⚠️ [W:onnxruntime] Failed to create CUDAExecutionProvider. Require cuDNN 9.*
```

**🎯 После установки cuDNN 9.x:**

```
🚀 Using CUDA GPU acceleration
🔧 ONNX Runtime providers: ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']
# Без предупреждений
```

**❌ Только CPU (если GPU недоступен):**

```
🔧 ONNX Runtime providers: ['CPUExecutionProvider']
```

## 💡 Программное использование

```python
from tone import StreamingCTCPipeline, DecoderType

# С GPU
pipeline = StreamingCTCPipeline.from_local('models',
                                          decoder_type=DecoderType.GREEDY,
                                          use_gpu=True)

# Без GPU
pipeline = StreamingCTCPipeline.from_local('models',
                                          decoder_type=DecoderType.GREEDY,
                                          use_gpu=False)
```

## ⚡ Производительность

Согласно документации проекта, на GPU производительность значительно выше:

| Device | Configuration | RPS   | SPS   |
| ------ | ------------- | ----- | ----- |
| T4     | TensorRT      | 5952  | 1786  |
| A30    | TensorRT      | 17408 | 5222  |
| A100   | TensorRT      | 26112 | 7833  |
| H100   | TensorRT      | 57344 | 17203 |
