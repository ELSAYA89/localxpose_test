from flask import Flask, request, render_template_string

app = Flask(__name__)

# Servir index.html y styles.css
@app.route("/")
def index():
    return open("index.html", "r", encoding="utf-8").read()

@app.route("/styles.css")
def css():
    return open("styles.css", "r", encoding="utf-8").read(), 200, {"Content-Type": "text/css"}

# Recibir datos
@app.route("/submit", methods=["POST"])
def submit():
    nombre = request.form.get("nombre")
    email = request.form.get("email")
    mensaje = request.form.get("mensaje")
    pais = request.form.get("pais")

    print("\n📩 Nuevo formulario recibido:")
    print(f"Nombre: {nombre}")
    print(f"Email: {email}")
    print(f"Mensaje: {mensaje}")
    print(f"País: {pais}\n")

    return "<h2>✅ Datos recibidos en tu PC/Termux</h2>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
