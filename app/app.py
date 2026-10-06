import os

from flask import Flask, jsonify

app = Flask(__name__)

ORDERS = [
    {
        "id": 1,
        "customer": "Akanksha",
        "product": "Laptop",
        "status": "CONFIRMED"
    },
    {
        "id": 2,
        "customer": "Rahul",
        "product": "Mobile",
        "status": "SHIPPED"
    },
    {
        "id": 3,
        "customer": "Priya",
        "product": "Headphones",
        "status": "DELIVERED"
    }
]

@app.route("/")
def home():
    return jsonify({
        "message": "OrderHub API",
        "environment": os.getenv("APP_ENV", "development")
    })

@app.route("/health")
def health():
    return jsonify({
        "status": "UP"
    })

@app.route("/orders")
def orders():
    return jsonify({
        "orders": ORDERS
    })

@app.route("/version")
def version():
    return jsonify({
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "build": os.getenv("BUILD_NUMBER", "unknown"),
        "commit": os.getenv("GIT_COMMIT", "unknown")
    })

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080"))
    )
