# 🚀 T-one Streaming Voice - Быстрое развертывание

## 📋 Автоматическая установка (Windows)

### Вариант 1: Полностью автоматический (рекомендуется)

**Windows:**

```bash
# 1. Клонируйте репозиторий
git clone <repository-url>
cd streaming-voice

# 2. Запустите автоматическую установку
setup.bat
# ИЛИ
make init

# 3. Запустите сервер
make up_dev          # Быстрый режим
make up_dev_full     # Точный режим с KenLM
```

**Linux/macOS:**

```bash
# 1. Клонируйте репозиторий
git clone <repository-url>
cd streaming-voice

# 2. Запустите автоматическую установку
./setup.sh
# ИЛИ
make init

# 3. Запустите сервер
make up_dev          # Быстрый режим
make up_dev_full     # Точный режим с KenLM
```

### Вариант 2: Пошаговая установка

```bash
# 1. Инициализация проекта (создает .venv, устанавливает зависимости, настраивает GPU)
make init

# 2. Скачайте дополнительные модели (опционально)
make download_full_models         # Полные модели с KenLM (5.6GB)

# 3. Запустите сервер
make up_dev          # Компактный режим
make up_dev_full     # Полный режим
```

## 🔧 Что происходит автоматически

### При выполнении `make init`:

1. **Создает виртуальное окружение** `.venv` (если не существует)
2. **Устанавливает все зависимости** включая `onnxruntime-gpu`
3. **Автоматически настраивает cuDNN** (вызывает `make setup_cudnn`)
4. **Готовит проект к работе** с GPU поддержкой

### При выполнении `make setup_cudnn`:

1. **Проверяет наличие cuDNN** в `libs/` папке
2. **Ищет системный cuDNN** в стандартных путях:
   - `C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll`
   - `C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll`
   - И другие версии
3. **Копирует в проект** если найден
4. **Скачивает портативную версию** если не найден
5. **Настраивает PATH** автоматически

### При выполнении `make up_dev` / `make up_dev_full`:

1. **Автоматически вызывает** `make setup_cudnn`
2. **Проверяет модели** и скачивает если нужно
3. **Настраивает окружение** с GPU поддержкой
4. **Запускает сервер** на http://localhost:8080

## 📦 Требования

### Обязательные:

- **Python 3.9+**
- **uv** - https://docs.astral.sh/uv/getting-started/installation/

### Для GPU (опционально):

- **NVIDIA GPU** с CUDA 12.x
- **CUDA Toolkit 12.x** - https://developer.nvidia.com/cuda-downloads

### Автоматически устанавливается:

- **ONNX Runtime GPU** (через uv)
- **cuDNN 9.x** (автоматически скачивается)
- **Модели AI** (автоматически скачиваются)

## 🎯 Результат

После установки вы увидите:

```
🚀 Using CUDA GPU acceleration
🔧 ONNX Runtime providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
💡 Используется Greedy декодер (компактный режим)
INFO: Application startup complete.
```

## 📁 Структура проекта после установки

```
streaming-voice/
├── libs/                    # cuDNN библиотеки (автоматически)
│   └── cudnn64_9.dll
├── models/                 # AI модели (автоматически)
│   ├── model.onnx          # Акустическая модель (144MB)
│   └── kenlm.bin           # Языковая модель (5.6GB, опционально)
├── init/                   # Скрипты инициализации
│   ├── windows.bat         # Windows инициализация
│   ├── unix.sh             # Linux/macOS инициализация
│   ├── find_cudnn.bat      # Поиск cuDNN (Windows)
│   └── README.md           # Документация скриптов
├── .venv/                  # Python окружение (автоматически)
├── setup.bat               # Быстрая установка (Windows)
├── setup.sh                # Быстрая установка (Linux/macOS)
└── ...
```

## 🔄 Обновление проекта

```bash
# Обновить код
git pull

# Обновить зависимости
uv sync --extra demo --extra dev

# Обновить модели (если нужно)
make download_models
make download_full_models

# Перезапустить сервер
make up_dev
```

## 🐛 Устранение проблем

### GPU не работает:

```bash
# Проверить CUDA
nvidia-smi

# Переустановить cuDNN
rm -rf libs/
make setup_cudnn

# Запустить без GPU
TONE_USE_GPU=false make up_dev
```

### Модели не загружаются:

```bash
# Очистить и переустановить
rm -rf models/
make download_models
```

## 📞 Поддержка

- **GPU Setup**: см. `GPU_SETUP.md`
- **Документация**: см. `README.md`
- **Проблемы**: создайте issue в репозитории
