import time
from fastapi import FastAPI
from fastapi.responses import FileResponse
from textblob import TextBlob
from prometheus_client import make_asgi_app, Counter, Histogram

app = FastAPI()

# 1. Mount the Prometheus Metrics Endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# 2. Define Custom DevOps Metrics
SENTIMENT_REQUEST_COUNT = Counter('sentiment_api_requests_total', 'Total requests to the sentiment API')
SENTIMENT_LATENCY = Histogram('sentiment_api_latency_seconds', 'Latency of sentiment analysis')

@app.get("/")
def serve_frontend():
    return FileResponse("index.html")

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "NLP Sentiment Analysis API"}

@app.get("/analyze")
def analyze_sentiment(text: str):
    # Start the stopwatch for Grafana
    start_time = time.time()
    
    # Run the real ML NLP analysis
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    
    # Determine the human-readable label
    if polarity > 0.1:
        label = "Positive 😃"
    elif polarity < -0.1:
        label = "Negative 😡"
    else:
        label = "Neutral 😐"
        
    # Stop the stopwatch and record the metrics
    process_time = time.time() - start_time
    SENTIMENT_LATENCY.observe(process_time)
    SENTIMENT_REQUEST_COUNT.inc()
    
    # Return the analysis results
    return {
        "analyzed_text": text,
        "mathematical_polarity": polarity,
        "sentiment_result": label,
        "model": "TextBlob NLP"
    }