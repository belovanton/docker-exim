FROM ubuntu:latest
MAINTAINER Anton Belov anton4@bk.ru

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
# Use source.list with all repositories and Yandex mirrors.
ADD sources.list /etc/apt/sources.list
RUN sed -i 's|://.*\..*\.com|://ru.archive.ubuntu.com|' /etc/apt/sources.list
RUN echo 'force-unsafe-io' | tee /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache
RUN echo 'Acquire::http {No-Cache=True;};' | tee /etc/apt/apt.conf.d/no-http-cache

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && apt-get clean && \
        apt-get -y install \
        pwgen python-setuptools \
        exim4 ca-certificates \
        wget && \
        apt-get clean && \
        rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory


# add custom exim.conf
ADD config/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN echo 'omsa-tuning.ru' > /etc/mailname

# add custom exim startup script
ADD scripts/exim-start.sh /usr/local/sbin/exim-start.sh
# Magento Initialization and Startup Script
ADD /config /config
ADD /scripts /scripts

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD /config/supervisor/supervisord.conf /etc/supervisord.conf

VOLUME /var/www
EXPOSE 80

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/bin/bash", "/scripts/start.sh"]
