# DIGICRON
An LED calculator smartwatch that runs 6502 code.

## Building and running
To build the DIGICRON firmware and operating system, run:

```bash
./build.sh
```

To build and run the firmware and the simulator, run the following commands:

```bash
./build.sh --sim
python3 -m http.server
```

Once the firmware has been built, the simulator will be available at [localhost:8000](http://localhost:8000).
