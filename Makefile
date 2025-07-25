CODE = tone

.PHONY: install
install:
	poetry install -E demo

.PHONY: lint
lint:
	# check package version
	python -c "import tone as a; exit(a.__version__ != \"`poetry version -s`\")"
	poetry check --lock
	# python linters
	ruff check $(CODE)
	ruff format --check $(CODE)

.PHONY: format
format:
	ruff format $(CODE)
	ruff check --fix $(CODE)

.PHONY: up_dev
up_dev:
	@echo "🚀 Запуск T-one (компактный режим по умолчанию)"
	@echo "📁 Модели будут загружены из папки models/ (если есть)"
	@if [ ! -d "models" ] || [ ! -f "models/model.onnx" ]; then \
		echo "⚠️  Модели не найдены в models/, скачиваем..."; \
		make download_models; \
	fi
	TONE_USE_COMPACT=true LOAD_FROM_FOLDER=models uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload

.PHONY: up_dev_new
up_dev_new:
	@echo "🚀 Запуск T-one с компактным декодером (без KenLM 5.46GB)"
	@echo "💡 Используется Greedy декодер - быстро и компактно для Mac"
	@echo "📁 Модели будут загружены из папки models/ (если есть)"
	@if [ ! -d "models" ] || [ ! -f "models/model.onnx" ]; then \
		echo "⚠️  Модели не найдены в models/, скачиваем..."; \
		make download_models; \
	fi
	TONE_USE_COMPACT=true LOAD_FROM_FOLDER=models uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload

.PHONY: download_models
download_models:
	@echo "📥 Скачивание моделей в папку models/"
	@mkdir -p models
	python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models', only_acoustic=True)"
	@echo "✅ Скачана только акустическая модель (144MB)"
	@echo "📊 Размер папки models/:"
	@du -sh models/ || echo "Папка models создана"

.PHONY: download_full_models  
download_full_models:
	@echo "📥 Скачивание ВСЕХ моделей (включая KenLM 5.46GB)"
	@mkdir -p models
	python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models')"
	@echo "✅ Скачаны все модели"
	@echo "📊 Размер папки models/:"
	@du -sh models/ || echo "Папка models создана"

.PHONY: up_dev_full
up_dev_full:
	@echo "� Запуски T-one с ПОЛНОЙ KenLM моделью (5.46GB)"
	@echo "⚠️  Это займет много времени и места!"
	@if [ ! -d "models" ] || [ ! -f "models/kenlm.bin" ]; then \
		echo "📥 Скачиваем полные модели..."; \
		make download_full_models; \
	fi
	TONE_USE_COMPACT=false LOAD_FROM_FOLDER=models uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload

.PHONY: show_models
show_models:
	@echo "📁 Содержимое папки models/:"
	@if [ -d "models" ]; then \
		ls -lah models/; \
		echo ""; \
		echo "📊 Общий размер:"; \
		du -sh models/; \
		echo ""; \
		if [ -f "models/model.onnx" ] && [ -f "models/kenlm.bin" ]; then \
			echo "✅ Полный набор моделей (Акустическая + KenLM)"; \
		elif [ -f "models/model.onnx" ]; then \
			echo "✅ Только акустическая модель (компактный режим)"; \
		else \
			echo "❌ Модели не найдены"; \
		fi \
	else \
		echo "Папка models/ не найдена. Запустите 'make download_models'"; \
	fi
