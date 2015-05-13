#cloud-config
define(`M4_ETCD_DISCOVERY', include(`discovery.inc'))dnl
include(`m4/license.inc')dnl
include(`m4/passwords.inc')dnl

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyukAK+pD6B3EkOlGtTC5Oyqx9N/1AZYqkaP0QEVn6pr+vkXlhE7CljfTT1egRGp76Ud18H3tCLDy6rhTpH5Kb+96eC8AWeKNrFbQWEjaBPbPlMUa96AeY+HXqH8JlHPkPu8k0BRVpnfeC6WKth8qU7j5CyqIH+SArKX5RvNgbqsxnR0X0XuvBKCiWt90yqnEC7JvCuznCKPeeLUOOjtf/9kYBfDIZdBKvIYxTZ7nx1WXQMeVxmsQrM29BPtZSXGhNQhDPHzIxDV8bNrXy5HXpCIQS3Qsv+T1TMgYjAl+C/1T+CW5wC+rLJTpdOjlRJThBYJw1xgQsfUIPedh3kEEpQ==
users:
  - name: eatnumber1
    groups:
      - sudo
      - docker
coreos:
  etcd:
    discovery: M4_ETCD_DISCOVERY
    addr: $private_ipv4:4001
    peer-addr: $private_ipv4:7001
  fleet:
    public-ip: $private_ipv4
  units:
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the timezone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone America/Los_Angeles
        RemainAfterExit=yes
        Type=oneshot
    - name: renameat2.service
      command: start
      content: |
        [Unit]
        Description=Install the renameat2 utility
        Requires=network-online.target
        After=network-online.target

        [Service]
        ExecStart=/bin/mkdir -p /opt/bin
        ExecStart=/usr/bin/curl -s -L -o /opt/bin/renameat2 https://gist.github.com/eatnumber1/f97ac7dad7b1f5a9721f/raw/3db4dbf58afd8d0024bef298806eec4f77c3e448/renameat2.x86_64
        ExecStart=/bin/chmod +x /opt/bin/renameat2
        RemainAfterExit=yes
        Type=oneshot
    - name: sbin-links.service
      command: start
      content: |
        [Unit]
        Description=Make /sbin not a symlink
        Requires=renameat2.service
        After=renameat2.service

        [Service]
        ExecStart=/bin/mkdir /sbin.new
        ExecStart=/bin/bash -c 'for f in /usr/sbin/*; do ln -s $f /sbin.new; done'
        ExecStart=/opt/bin/renameat2 -e /sbin.new /sbin
        ExecStart=/bin/rm -rf /sbin.new
        RemainAfterExit=yes
        Type=oneshot
    - name: bin-links.service
      command: start
      content: |
        [Unit]
        Description=Make /bin not a symlink
        Requires=renameat2.service
        After=renameat2.service

        [Service]
        ExecStart=/usr/bin/mkdir /bin.new
        ExecStart=/usr/bin/bash -c 'for f in /usr/bin/*; do ln -s $f /bin.new; done'
        ExecStart=/opt/bin/renameat2 -e /bin.new /bin
        ExecStart=/bin/rm -rf /bin.new
        RemainAfterExit=yes
        Type=oneshot
    - name: objectivefs.service
      command: start
      content: |
        [Unit]
        Description=Install ObjectiveFS
        Requires=sbin-links.service bin-links.service
        After=sbin-links.service bin-links.service

        [Service]
        ExecStart=/bin/mkdir -p /opt/bin
        ExecStart=/usr/bin/curl -s -L -o /opt/bin/mount.objectivefs.bin https://github.com/eatnumber1/docker-objectivefs/raw/master/mount.objectivefs
        ExecStart=/usr/bin/curl -s -L -o /opt/bin/mount.objectivefs https://gist.githubusercontent.com/eatnumber1/d654b0366dd7201475ae/raw/12c22961be11733e3a34dce7d1e0c5b89fc88eb1/mount.objectivefs
        ExecStart=/usr/bin/curl -s -L -o /opt/bin/fusermount https://gist.github.com/eatnumber1/db7f2a29cded7c6e5adc/raw/515e1a645bbff65c3065c11e2fdf80dfcec5c1e6/fusermount
        ExecStart=/bin/chmod +x /opt/bin/mount.objectivefs.bin /opt/bin/mount.objectivefs /opt/bin/fusermount
        ExecStart=/bin/ln -s /opt/bin/mount.objectivefs /sbin
        ExecStart=/bin/ln -s /opt/bin/fusermount /bin
        RemainAfterExit=yes
        Type=oneshot
    - name: space.mount
      command: start
      content: |
        [Unit]
        Description=Mount space to /space
        Requires=objectivefs.service
        After=objectivefs.service

        [Mount]
        Environment="AWS_ACCESS_KEY_ID=M4_AWS_ACCESS_KEY_ID"
        Environment="AWS_SECRET_ACCESS_KEY=M4_AWS_SECRET_ACCESS_KEY"
        Environment="AWS_DEFAULT_REGION=http://storage.googleapis.com"
        Environment="OBJECTIVEFS_LICENSE=M4_OBJECTIVEFS_LICENSE"
        Environment="OBJECTIVEFS_PASSPHRASE=M4_OBJECTIVEFS_PASSPHRASE"
        What=objectivefs
        Where=/space
        Type=objectivefs
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start

# vim:et ts=2 sw=2 sts=2 ai ft=yaml
