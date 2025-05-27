import os
import subprocess
import shutil
from pathlib import Path

# 1. Percorso della cartella con i notebook
NOTEBOOK_DIR = Path(".")
TEMP_DIR = Path("temp_py_scripts")
REQ_FILE = Path("requirements.txt")

# 2. Crea una cartella temporanea per i file .py
TEMP_DIR.mkdir(exist_ok=True)

# 3. Trova e converte tutti i notebook in .py
for nb_path in NOTEBOOK_DIR.glob("*.ipynb"):
    subprocess.run(["jupyter", "nbconvert", "--to", "script", str(nb_path)])
    py_file = nb_path.with_suffix(".py")
    if py_file.exists():
        shutil.move(str(py_file), TEMP_DIR / py_file.name)

# 4. Usa pipreqs per generare requirements.txt
subprocess.run([
    "pipreqs", str(TEMP_DIR),
    "--force",
    "--savepath", str(REQ_FILE)
])

# 5. Aggiungi 'notebook' alla fine (se non già incluso)
with open(REQ_FILE, "a+") as f:
    f.seek(0)
    content = f.read()
    if "notebook" not in content:
        f.write("\nnotebook\n")

# 6. Stampa il percorso del file requirements.txt
print(f"📄 requirements.txt salvato in: {REQ_FILE.resolve()}")
# 7. Stampa un messaggio di completamento
print("✅ Generazione di requirements.txt completata con successo!")
# 8. Pulizia dei file .py temporanei
for py_file in TEMP_DIR.glob("*.py"):
    py_file.unlink()
# 9. Rimuovi la cartella temporanea
if TEMP_DIR.exists():
    TEMP_DIR.rmdir()
# 10. Stampa un messaggio di pulizia completata
print("🧹 Pulizia dei file temporanei completata!")
# 11. Stampa un messaggio di fine script
print("🔚 Script di generazione requirements.txt terminato!")