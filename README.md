# sdr-enthusiasts/docker-airnavradar

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/radarbox/latest)](https://hub.docker.com/r/mikenye/radarbox)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [AirNav Radar](https://www.airnavradar.com)'s `rbfeeder`. Designed to work in tandem with [sdr-enthusiasts/adsb-ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder). Builds and runs on `x86_64`, `arm64` and `arm32v7`.

`rbfeeder` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to Airnav Radar.

For more information on what `rbfeeder` is, see here: [sharing-data](https://www.airnavradar.com/sharing-data).

## Supported tags and respective Dockerfiles

- `latest` (`main` branch, `Dockerfile`)
- `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
- Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

- `amd64`: Linux x86-64
- `arm32v7`, `armv7l`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2B/3B)
- `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)

## Obtaining a Airnav Radar Sharing Key

First-time users should obtain a Airnav Radar sharing key.

In order to obtain a Airnav Radar sharing key, on the first run of the container, `rbfeeder` will generate a sharing key and print this to the container log.

```shell
timeout 300s docker run \
    --rm \
    -it \
    -e BEASTHOST=YOURBEASTHOST \
    -e LAT=YOURLATITUDE \
    -e LONG=YOURLONGITUDE \
    -e ALT=YOURALTITUDE \
    ghcr.io/sdr-enthusiasts/docker-airnavradar:latest
```

This will run the container for five minutes, allowing a sharing key to be generated.

You should obviously replace `YOURBEASTHOST`, `YOURLATITUDE`, `YOURLONGITUDE` and `YOURALTITUDE` with appropriate values.

Shortly after the container launches, you should be presented with:

```text
[2020-04-02 11:36:31]  Empty sharing key. We will try to create a new one for you!
[2020-04-02 11:36:32]  Your new key is g45643ab345af3c5d5g923a99ffc0de9. Please save this key for future use. You will have to know this key to link this receiver to your account in airnavradar.com. This key is also saved in configuration file (/etc/rbfeeder.ini)
```

Take a note of the sharing key, as you'll need it when launching the container.

If you're not a first time user and are migrating from another installation, you can retrieve your sharing key using either of the following methods:

- SSH onto your existing receiver and run the command `rbfeeder --showkey --no-start`
- SSH onto your existing receiver and run the command `grep key= /etc/rbfeeder.ini`

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name rbfeeder \
 -e TZ="YOURTIMEZONE" \
 -e BEASTHOST=YOURBEASTHOST \
 -e LAT=YOURLATITUDE \
 -e LONG=YOURLONGITUDE \
 -e ALT=YOURALTITUDE \
 -e SHARING_KEY=YOURSHARINGKEY \
 ghcr.io/sdr-enthusiasts/docker-airnavradar:latest
```

You should obviously replace `YOURBEASTHOST`, `YOURLATITUDE`, `YOURLONGITUDE`, `YOURALTITUDE` and `YOURSHARINGKEY` with appropriate values.

For example:

```shell
docker run \
 -d \
 --rm \
 --name rbfeeder \
 -e TZ="Australia/Perth" \
 -e BEASTHOST=readsb \
 -e LAT=-33.33333 \
 -e LONG=111.11111 \
 -e ALT=90 \
 -e SHARING_KEY=g45643ab345af3c5d5g923a99ffc0de9 \
 ghcr.io/sdr-enthusiasts/docker-airnavradar:latest
```

Please note, the altitude figure is given in metres and no units should be specified.

## Up-and-Running with Docker Compose

```yaml
services:
  airnavradar:
    image: ghcr.io/sdr-enthusiasts/docker-airnavradar:latest
    container_name: airnavradar
    restart: always
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=ultrafeeder
      - LAT=-33.33333
      - LONG=111.11111
      - ALT=90
      - SHARING_KEY=g45643ab345af3c5d5g923a99ffc0de9
```

## Claiming Your Receiver

Once your container is up and running, you should claim your receiver.

1. Go to <https://www.airnavradar.com/>
1. Create an account or sign in
1. Claim your receiver by visiting <https://www.airnavradar.com/raspberry-pi/claim> and following the instructions

## Connection Errors

Before raising an issue regarding connection errors, please wait at least 10 minutes. The `rbfeeder` binary is configured to attempt to connect to a collection of servers in a round-robin method. It appears normal for some servers to reject the connection, so it may take several minutes to find an available server and connect. In the example below, it took approximately 6 minutes from container start to connection established.

You can try to solve this by setting this parameter:

```yaml
- RB_SERVER=true
```

This will enforce the use of a hardcoded IP address that is known to work (as of 22-Nov-2023). It will connect you to a European server if you are located in the Eastern Hemisphere (incl Asia/Oceania), or to a US based server if you are in the Americas.

You may also receive a spurious error `Error authenticating Sharing-Key: Invalid sharing-key`. Provided you have entered your sharing key correctly, just ignore this for several minutes.

Here is some example output with RBFeeder Version 1.0.10 (build 20231120150000) showing the aforementioned behaviour:

```shell
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]  Starting RBFeeder Version 1.0.10 (build 20231120150000)
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]  Using configuration file: /etc/rbfeeder.ini
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]  Network-mode enabled.
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]     Remote host to fetch data: 172.20.0.11
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]     Remote port: 30005
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]     Remote protocol: BEAST
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]  Using GNSS (when available)
[2023-11-22 21:59:06.966][rbfeeder] [2023-11-22 21:59:06]  Start date/time: 2023-11-22 21:59:06
[2023-11-22 21:59:06.972][rbfeeder] [2023-11-22 21:59:06]  Socket for ANRB created. Waiting for connections on port 32088
[2023-11-22 21:59:08.039][rbfeeder] [2023-11-22 21:59:08]  Connection established.
[2023-11-22 21:59:18.154][rbfeeder] [2023-11-22 21:59:18]  Could not start connection. Timeout.

...

[2023-11-22 22:05:29.223][rbfeeder] [2023-11-22 22:05:29]  Connection established.
[2023-11-22 22:05:29.456][rbfeeder] [2023-11-22 22:05:29]  Client type: Raspberry Pi
[2023-11-22 22:05:29:29.524][rbfeeder] [2023-11-22 22:05:29]  Connection with RadarBox24 server OK! Key accepted by server.
[2023-11-22 22:05:29.524][rbfeeder] [2023-11-22 22:05:29]  This is your station serial number: EXTRPIxxxxxx
```

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable     | Purpose                                                                                                                                                                                                                                                                 | Default  |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `BEASTHOST`              | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090/readsb)                                                                                                                                                                                                      | `readsb` |
| `BEASTPORT`              | Optional. TCP port number of Mode-S/BEAST provider (dump1090/readsb)                                                                                                                                                                                                    | `30005`  |
| `UAT_RECEIVER_HOST`      | Optional. IP/Hostname of an external UAT decoded JSON provider (eg: dump978-fa).                                                                                                                                                                                        |          |
| `UAT_RECEIVER_PORT`      | Optional. TCP port number of the external UAT decoded JSON provider.                                                                                                                                                                                                    | `30979`  |
| `SHARING_KEY`            | Required. Airnav Radar Sharing Key                                                                                                                                                                                                                                      |          |
| `LAT`                    | Required. Latitude of the antenna                                                                                                                                                                                                                                       |          |
| `LONG`                   | Required. Longitude of the antenna                                                                                                                                                                                                                                      |          |
| `ALT`                    | Required. Altitude in _metres_                                                                                                                                                                                                                                          |          |
| `TZ`                     | Optional. Your local timezone                                                                                                                                                                                                                                           | GMT      |
| `STATS_INTERVAL_MINUTES` | Optional. How often to print statistics, in minutes.                                                                                                                                                                                                                    | `5`      |
| `VERBOSE_LOGGING`        | Optional. Set to `true` for no filtering of `rbfeeder` logs.                                                                                                                                                                                                            | `false`  |
| `DEBUG_LEVEL`            | Optional. Set to any number between `0` and `8` to increase verbosity of `rbfeeder` logs.                                                                                                                                                                               | `0`      |
| `ENABLE_MLAT`            | Option. Set to `true` to enable MLAT inside of the container. See [MLAT note](#mlat) below                                                                                                                                                                              | `true`   |
| `MLAT_RESULTS_BEASTHOST` | a hostname or IP, where MLAT results should be sent. (disables 30105 results listen port)                                                                                                                                                                               |          |
| `MLAT_RESULTS_BEASTPORT` | a port number, specify the TCP port number where MLAT results should be sent.                                                                                                                                                                                           | `30104`  |
| `RB_SERVER`              | Optional. If set to `true`, the container will attempt to connect to one of two Airnav Radar Servers that are known to work as of 22-Nov-2023. You can also explicitly set it to a hostname or IP address. If unset, the default settings of Airnav Radar will be used. | Unset    |

## Ports

The following TCP ports are used by this container:

- `32088` - `rbfeeder` listens on this port, however I can't find the use for this port...
- `30105` - `mlat-client` listens on this port to provide MLAT results. (mlat results listen port disabled when `MLAT_RESULTS_BEASTHOST` is set to work around rbfeeder bug)

## MLAT

You may find that MLAT in your container will often times spit out errors in your logs, such as

```shell
[rbfeeder] Disconnecting from mlat1.rb24.com:40900: No data (not even keepalives) received for 60 seconds
[rbfeeder] Connected to multilateration server at mlat1.rb24.com:40900, handshaking
```

This is likely, but not always, not caused by anything you are doing, but is instead caused by the Airnav Radar server itself and as such there isn't anything you can do to fix it. You will see in your Airnav Radar stats very little, if any, MLAT targets from your feeder while it is doing this.

To stop the feeder from spamming your logs you can set `ENABLE_MLAT=false` in your environment configuration for Airnav Radar and it will stop the MLAT service, and the log messages. Please note that if you do this, and you use [MLAT Hub](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder?tab=readme-ov-file#configuring-the-built-in-mlat-hub) please remove Airnav Radar from your `ULTRAFEEDER_CONFIG` parameter.

## Using the container on a Raspberry Pi 5

The container internally uses a binary called `rbfeeder` to send data to the Airnav Radar service. This binary is provided as closed-source by AirNav (the company that operates Airnav Radar) and is only available in armhf (32-bit) format using 4kb kernel pages. This will work well on Raspberry Pi 3B+, 4B, and other ARM-based systems that use either 32-bits or 64-bits Debian Linux with a 4kb kernel page size. It also works well on x86 Linux where we use the `qemu` ARM emulator to run the binary.

Debian Linux for Raspberry Pi 5 uses by default a kernel with 16kb page sizes, and this is not compatible with the `rbfeeder` binary. You will see failures in your container logs.

You can check your kernel page size with this command: getconf PAGE_SIZE . If the value returned is 4096, then all is good. If it is something else (for example 16384 for 16kb page size), you will need to implement the following work-around:

Add the following to /boot/firmware/config.txt (Debian 12 Bookworm or later) or /boot/config.txt (Debian 11 Bullseye or earlier) to use a kernel with page size of 4kb. This will make CPU use across your Raspberry Pi 5 slightly less efficient, but it will solve the issue for [many software packages that have the same issue](https://github.com/raspberrypi/bookworm-feedback/issues/107). After changing this, you must reboot your system for it to take effect:

```text
kernel=kernel8.img
```

(a one-time command to add this would be:)

```bash
echo "kernel=kernel8.img" | sudo tee -a /boot/firmware/config.txt >/dev/null
```

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-airnavradar/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

If you're getting continual segmentation faults inside this container, see: <https://github.com/sdr-enthusiasts/docker-airnavradar/issues/16#issuecomment-699627387>
