FROM python:3.11-slim-trixie

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

ENV PATH="/app/.venv/bin:$PATH"

COPY .python-version pyproject.toml uv.lock ./

# latest recommendation
RUN uv sync --frozen

RUN mkdir -p models

# copy the application code
COPY scripts/predict.py  ./predict.py
COPY scripts/preprocessing.py ./preprocessing.py
COPY models/bioactivity_prediction_rf_model.joblib ./models/bioactivity_prediction_rf_model.joblib

EXPOSE 9696

#ENTRYPOINT ["uvicorn", "predict:app", "--host", "0.0.0.0", "--port", "9696"]

ENTRYPOINT ["python", "predict.py"]
