"""
plot_adc.py — Receive 128 ADC samples over serial and plot the waveform.

Usage:
    pip install pyserial numpy matplotlib
    python plot_adc.py

Adjust SERIAL_PORT to match your USB-to-serial adapter.
On macOS: ls /dev/tty.usb*   On Windows: check Device Manager for COMx port.
"""
import serial
import numpy as np
import matplotlib.pyplot as plt
import time

# ---- Configuration ----
SERIAL_PORT = 'COM5'                       # <-- CHANGE THIS (e.g. COM3 on Windows)
BAUD_RATE   = 9600
NUM_SAMPLES = 128
SAMPLE_RATE = 10_000    # 10 kHz (must match Timer0 setup in main.s)
VREF        = 4.096     # ADC positive reference voltage

# ---- Open serial port and wait for data ----
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=30)

# Flush any stale data from the serial buffer (idle line 0xFF bytes)
time.sleep(0.5)
ser.reset_input_buffer()

print(f"Listening on {SERIAL_PORT} @ {BAUD_RATE} baud...")
print("Reset the PIC now (if not already running)...")

# Synchronise: look for the 4-byte preamble 0xAA 0x55 0xFF 0xFF
# This unique sequence cannot appear from idle-line noise (all 0xFF)
MARKER = bytes([0xAA, 0x55, 0xFF, 0xFF])
buf = bytearray()
while True:
    b = ser.read(1)
    if len(b) == 0:
        raise TimeoutError("Timed out waiting for start marker")
    buf.append(b[0])
    # Only keep the last 4 bytes
    if len(buf) > 4:
        buf.pop(0)
    if bytes(buf) == MARKER:
        break

print("Start marker received — reading samples...")

# Read 256 bytes (128 samples × 2 bytes)
raw = ser.read(NUM_SAMPLES * 2)
ser.close()

if len(raw) != NUM_SAMPLES * 2:
    raise RuntimeError(f"Expected {NUM_SAMPLES*2} bytes, got {len(raw)}")

# ---- Parse 12-bit ADC values (low byte first, high byte second) ----
# PIC18F87K22 has a 12-bit ADC, right-justified: ADRESH[3:0]:ADRESL[7:0]
adc_values = []
bad_bytes = 0
for i in range(0, len(raw), 2):
    low  = raw[i]
    high = raw[i + 1]
    if high > 0x0F:
        bad_bytes += 1
    val  = ((high & 0x0F) << 8) | low   # right-justified 12-bit
    adc_values.append(val)

if bad_bytes > 0:
    print(f"WARNING: {bad_bytes}/{NUM_SAMPLES} samples had high byte > 0x0F "
          f"— possible byte misalignment!")

adc_values = np.array(adc_values)
voltages   = adc_values / 4095.0 * VREF

# ---- Time axis ----
t_ms = np.arange(NUM_SAMPLES) / SAMPLE_RATE * 1000   # milliseconds

# ---- Plot ----
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 7), sharex=True)

ax1.plot(t_ms, adc_values, '-o', markersize=2, color='tab:blue')
ax1.set_ylabel('ADC Value (0-4095)')
ax1.set_title(f'ADC Samples — {SAMPLE_RATE/1000:.0f} kHz sample rate, {NUM_SAMPLES} points')
ax1.grid(True)

ax2.plot(t_ms, voltages, '-o', markersize=2, color='tab:orange')
ax2.set_xlabel('Time (ms)')
ax2.set_ylabel('Voltage (V)')
ax2.set_ylim(0, VREF)
ax2.grid(True)

plt.tight_layout()
plt.savefig('adc_waveform.png', dpi=150)
print("Saved plot to adc_waveform.png")
plt.show()