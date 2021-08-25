[![Build Image](https://github.com/SamuelBartik/route2me/actions/workflows/BuildImage.yml/badge.svg?branch=master)](https://github.com/SamuelBartik/route2me/actions/workflows/BuildImage.yml)

# Route2Me - Keeps your containers connected to wireguard
This docker mod helps you with keeping all desired containers connected to your wireguard container. You won't need to recreate all your dependant containers manually after making a change in the wireguard container configuration. This mod will all handle that for you.

# How does it work?
The mod works by running a service after startup which checks all dependant containers and their configured network_mode value. If they don't refer to wireguard container or the data is outdated, the dependant container will get recreated with similiar tweaked configuration that now makes it able to route traffic through wireguard container.

Optionally you can set a timeout value that will perform the same check again as stated above.

# Configuration
First of all, you need to give the wireguard container read-only access to ``docker.sock`` file in order to allow this to work. The mod is configurable via two ways: enviroment variables and labels:

### Enviroment variables
You set them on the wireguard container. They are all optional:

| Variable | Default      | Definition |
| -------- | ------------ | ---------- |
| R2M_DOCKER_SOCK | /var/run/docker.sock | Path to ``docker.sock`` file |
| R2M_TIMEOUT | -1 | Number of seconds to wait before performing another check. Enter ``-1`` to run check only once, after the wireguard container has started. |
| R2M_LOG_PATH | /config/logs/route2me.log | Path to a file to log to.|
| R2M_LOG_LEVEL | INFO | Set minimal level that should be logged to the file. Possible values: ``CRITICAL``, ``ERROR``, ``WARNING``, ``INFO``, ``DEBUG``, ``NOTSET`` |
| R2M_HEALTHCHECK | False | Wait until the wireguard container becomes healthy. Only then begin the checks. If true, you **WILL NEED** to specify ``healtcheck`` manually in the container configuration!| 

### Labels
Add the ``com.route2me.slave`` label to all dependant containers that you wish to check. The wireguard container will be found automatically if its hostname corresponds to its container ID. If you have changed hostname of a wireguard container to custom value, you need to add the ``com.route2me.master`` label to it as well.

> NOTE: All dependant containers need to be started before the wireguard container. You can achieve this by ``depends_on`` in ``docker-compose.yml``.

### Example docker-compose.yml file:
```yml
version: "2.1"
services:
  wireguard:
    image: ghcr.io/linuxserver/wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - DOCKER_MODS=samuelbartik/route2me # <--- Required
      - R2M_DOCKER_SOCK=/var/run/docker.sock # <--- Optional
      - R2M_TIMEOUT=-1 # <--- Optional
      - R2M_LOG_PATH=/config/logs/route2me.log # <--- Optional
      - R2M_LOG_LEVEL=INFO # <--- Optional
      - R2M_HEALTHCHECK=True # <--- Optional
    volumes:
      - /path/to/appdata/config:/config
      - /lib/modules:/lib/modules
      - /var/run/docker.sock:/var/run/docker.sock:ro # <--- Required
    healthcheck: # <--- Required if R2M_HEALTHCHECK=True
      test: "ping -c 1 www.google.com || exit 1"
      interval: 2m30s
      timeout: 10s
      retries: 3
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    labels: 
      - com.route2me.master # <--- Required only if you have changed the hostname of wireguard container
    restart: unless-stopped

  qbittorrent:
    image: ghcr.io/linuxserver/qbittorrent
    network_mode: "none" # <--- Optional. This will be swapped out for the wireguard container by the mod
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - WEBUI_PORT=8080
    volumes:
      - /path/to/appdata/config:/config
      - /path/to/downloads:/downloads
    ports:
      - 6881:6881
      - 6881:6881/udp
      - 8080:8080
    depends_on:
      - wireguard # <--- Required
    labels:
      - com.route2me.slave # <--- Required
    restart: unless-stopped```
