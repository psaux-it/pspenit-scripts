# Pentest Service Scripts RCS (RUN-CATCH-SHARE)

**helper.sh** --> wrapper script between java and cmd. We need it because we haven't implemented message queuer like rabbitmq to java, also we have no distributed system, load balancing etc. Somehow we need to control server load and process timeouts. For now, doing well. When you add new pentest tool to [pspenit](https://github.com/psaux-it/pspenit) please connect shell command via this script.

**jvm_ops.sh** --> Project's build, deploy, boot time automation. When you add new pentest tool to [pspenit](https://github.com/psaux-it/pspenit) please adjust global_vars and add binary paths.

![ezgif com-video-to-gif (3)](https://user-images.githubusercontent.com/25556606/226108577-f50e2dc6-051e-49c1-a24e-66e9fb265c75.gif)

**proxy.sh** --> To keep our server IP's clean while testing we used to use public proxies before. This is deprecated now. We have our own squid proxy server 159.69.183.155, sure need a proxy chain but for now It is ok.

**webnettools.service** --> This is systemd service that start our service at boot time via jvm_ops.sh.
