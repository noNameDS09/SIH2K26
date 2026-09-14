.PHONY: api api-local web health test-api voice

api:
	docker compose up --build api

api-local:
	cd apps/api && .venv/bin/uvicorn kalasetu_api.main:app --app-dir src --reload --host 0.0.0.0 --port 8000

web:
	npm --prefix apps/web run dev

health:
	curl -s http://localhost:8000/health

test-api:
	cd apps/api && .venv/bin/pytest

voice:
	cd apps/api && PYTHONPATH=src .venv/bin/streamlit run streamlit_cataloger.py
