# icecc-jobs.sh
Simple bash script that queries icecream scheduler to discover the available job count in the network.
## Usage:
```
icecc-jobs.sh [--help] [-p | --port <port>] [-s | --scheduler <scheduler>]
```
  - `-h | --help`: show help.
  - `-p | --port <port>`: icecc-scheduler port, defaults to 8766.
  - `-s | --scheduler <scheduler>`: scheduler host address, allows to skip network scan (faster result).

If the scheduler address is not specified, the script will scan over all available networks.
The first computer found with icecc-scheduler port open will be considered to be the scheduler.
