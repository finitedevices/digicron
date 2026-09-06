# DIGICRON
An LED calculator smartwatch that runs 6502 code.

## Installing dependencies
Before building the DIGICRON firmware and operating system, you must first have the required development dependencies installed. To install the dependencies, run:

```bash
./build.sh --install-dev
```

## Building and running
To build the DIGICRON firmware and operating system, run:

```bash
./build.sh
```

To build and flash the firmware to a device over USB, run:

```bash
./build.sh --upload
```

To build the firmware and run it within the web-based simulator, run these commands:

```bash
./build.sh --sim
python3 -m http.server
```

Once the firmware has been built, the simulator will be available at [localhost:8000](http://localhost:8000).
