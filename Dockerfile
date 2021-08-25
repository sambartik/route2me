FROM scratch

LABEL maintainer="SamuelBartik"
LABEL org.opencontainers.image.source = "https://github.com/SamuelBartik/route2me"
LABEL org.opencontainers.image.title = "Route2Me"
LABEL org.opencontainers.image.description = "Linuxserver.io docker mod for wireguard container to help you keep your containers connected to wireguard."

# copy local files
COPY root/ /
