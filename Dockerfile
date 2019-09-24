FROM alpine:3.8

RUN apk add audit
RUN apk add --no-cache jq=1.6_rc1-r1

COPY startup.sh /opt/pauditd/startup.sh
RUN chmod 750 /opt/pauditd/startup.sh

RUN ln -sf /usermgmt/etc/passwd /etc/passwd

ADD pauditd /opt/pauditd/pauditd

ENTRYPOINT [ "/opt/pauditd/startup.sh" ]
