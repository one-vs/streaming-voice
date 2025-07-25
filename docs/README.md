# 📚 T-one Streaming Voice - Документация

Добро пожаловать в документацию проекта T-one Streaming Voice! Здесь вы найдете все необходимые руководства для установки, настройки и использования системы.

## 🚀 Быстрый старт

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Полное руководство по развертыванию проекта
- **[GPU_SETUP.md](GPU_SETUP.md)** - Настройка GPU ускорения (CUDA + cuDNN)

## 📖 Основная документация

### 🔧 Установка и настройка
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Автоматическая установка для Windows/Linux/macOS
- **[GPU_SETUP.md](GPU_SETUP.md)** - Подробная настройка GPU поддержки

### ⚡ Производительность
- **[performance_testing.md](performance_testing.md)** - Performance Testing Guide (English)
- **[performance_testing.ru.md](performance_testing.ru.md)** - Тестирование производительности (Русский)

### 🚀 Продвинутые возможности
- **[triton_inference_server.md](triton_inference_server.md)** - Triton Inference Server Guide (English)
- **[triton_inference_server.ru.md](triton_inference_server.ru.md)** - Triton Inference Server (Русский)

## 🎯 Рекомендуемый порядок чтения

### Для новых пользователей:
1. **[DEPLOYMENT.md](DEPLOYMENT.md)** - начните здесь для установки
2. **[GPU_SETUP.md](GPU_SETUP.md)** - настройте GPU для максимальной производительности

### Для разработчиков:
1. **[performance_testing.md](performance_testing.md)** - тестирование производительности
2. **[triton_inference_server.md](triton_inference_server.md)** - продакшн развертывание

## 🔗 Быстрые ссылки

### Установка
```bash
# Автоматическая установка
make init                # Полная инициализация
setup.bat                # Windows быстрая установка
./setup.sh               # Linux/macOS быстрая установка
```

### Запуск
```bash
make up_dev              # Компактный режим (быстро)
make up_dev_full         # Полный режим с KenLM (точно)
```

### GPU настройка
```bash
make setup_cudnn         # Автоматическая настройка cuDNN
make find_cudnn          # Расширенный поиск cuDNN
```

## 📁 Структура документации

```
docs/
├── README.md                    # Этот файл - индекс документации
├── DEPLOYMENT.md                # Руководство по развертыванию
├── GPU_SETUP.md                 # Настройка GPU ускорения
├── performance_testing.md       # Тестирование производительности (EN)
├── performance_testing.ru.md    # Тестирование производительности (RU)
├── triton_inference_server.md   # Triton Inference Server (EN)
└── triton_inference_server.ru.md # Triton Inference Server (RU)
```

## 🆘 Получение помощи

### Проблемы с установкой
- Проверьте **[DEPLOYMENT.md](DEPLOYMENT.md)** раздел "Устранение проблем"
- Убедитесь, что у вас установлен `uv`: https://docs.astral.sh/uv/

### Проблемы с GPU
- Изучите **[GPU_SETUP.md](GPU_SETUP.md)** для подробной диагностики
- Проверьте наличие CUDA: `nvidia-smi`
- Попробуйте без GPU: `TONE_USE_GPU=false make up_dev`

### Проблемы с производительностью
- Ознакомьтесь с **[performance_testing.md](performance_testing.md)**
- Убедитесь, что GPU используется: смотрите логи запуска

## 🔄 Обновления документации

Документация обновляется вместе с кодом. При обновлении проекта:

```bash
git pull                 # Обновить код и документацию
make init                # Переустановить зависимости если нужно
```

## 📞 Поддержка

- **Issues**: Создайте issue в репозитории для сообщения о проблемах
- **Discussions**: Используйте GitHub Discussions для вопросов
- **Wiki**: Дополнительные материалы в Wiki репозитория

---

**Начните с [DEPLOYMENT.md](DEPLOYMENT.md) для быстрой установки!** 🚀
