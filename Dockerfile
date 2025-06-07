FROM python:3.9-slim 

WORKDIR /app

# Combine all pip installs into one RUN command to reduce layers
RUN pip install --no-cache-dir \
    streamlit \
    numpy \
    pandas \
    scikit-learn \
    google-generativeai

COPY . .
EXPOSE 8501

CMD ["streamlit", "run", "my_deploy.py", "--server.port=8501", "--server.address=0.0.0.0"]