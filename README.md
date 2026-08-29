# DIGICRON
An LED calculator smartwatch that runs 6502 code.

## Building and running
To build the DIGICRON firmware and operating system, run:

```bash
./build.sh
```

To flash the firmware to a device over USB, run:

```bash
./build.sh --upload
```

To build the firmware and run it within the web-based simulator, run:

```bash
./build.sh --sim
python3 -m http.server
```

Once the firmware has been built, the simulator will be available at [localhost:8000](http://localhost:8000).
