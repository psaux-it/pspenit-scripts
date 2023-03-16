# Pentest Service Scripts RCS (RUN-CATCH-SHARE)

**helper.sh** --> wrapper script between java and cmd. We need it because we haven't implemented message queuer like rabbitmq to java, also we have no distributed system, load balancing etc. Somehow we need to control server load and process timeouts. For now, doing well.

**jvm_ops.sh** --> Project^s build and deploy automation

**proxy.sh** --> To keep our server IP's clean while testing we used to use public proxies before. This is deprecated now. We have our own proxy server, sure need a proxy chain but for now It is ok.

**webnettools.service** --> This is systemd service that start our service at boot time.
