from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    return "ZSR: wersja 1\n"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
