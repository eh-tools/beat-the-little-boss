"""Independent-process click target for manual Windows passthrough verification.

Run with pythonw. Place the desktop pet over the large canvas, then click
transparent margins and a speech bubble. Each received click is shown and
recorded locally. This helper never injects input or modifies other windows.
"""

import json
from pathlib import Path
import tkinter as tk

log_path = Path(__file__).resolve().parents[1] / ".scratch/desktop-pet/passthrough-clicks.json"
window = tk.Tk()
window.title("Desktop Pet · Passthrough target")
window.geometry("720x520+160+160")
window.configure(bg="#efe6d1")
heading = tk.Label(window, text="Independent application · click receiver", font=("Segoe UI", 18), bg="#efe6d1", fg="#303247")
heading.pack(pady=20)
counter = tk.Label(window, text="Received clicks: 0", font=("Segoe UI", 16), bg="#efe6d1", fg="#303247")
counter.pack(pady=8)
canvas = tk.Canvas(window, background="#c5ded6", highlightthickness=0)
canvas.pack(fill="both", expand=True, padx=24, pady=24)
canvas.create_text(330, 50, text="Put the pet here. Click the transparent margin / speech bubble.", fill="#303247", font=("Segoe UI", 12))
events = []


def record(event):
    events.append({"x": event.x_root, "y": event.y_root})
    counter.configure(text=f"Received clicks: {len(events)}")
    canvas.create_oval(event.x - 4, event.y - 4, event.x + 4, event.y + 4, fill="#b55450", outline="")
    log_path.write_text(json.dumps(events, indent=2), encoding="utf-8")


canvas.bind("<Button-1>", record)
window.mainloop()
