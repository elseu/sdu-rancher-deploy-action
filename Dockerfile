FROM blackholegalaxy/rancher-cli:2.4.0

RUN apk add bash gettext --no-cache --update

COPY deploy.bash /deploy.bash
RUN chmod +x /deploy.bash

ENTRYPOINT [ "/deploy.bash" ]
