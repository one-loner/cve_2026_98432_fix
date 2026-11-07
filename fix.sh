#!/bin/bash
if (($EUID !=0)); then
     echo Script must be run by root.
     exit
fi

apt install -y nftables

cat > /etc/cve-2026-98432.nft <<'EOF'
table ip cve_2026_98432 {
    chain pre {
        type filter hook prerouting priority -300; policy accept;
        meta l4proto tcp ip hdrlength gt 5 counter drop
    }
}
EOF


cat > /etc/systemd/system/cve-2026-98432.service <<'EOF'
[Unit]
Description=Mitigation for CVE-2026-98432
After=network-pre.target nftables.service firewalld.service ufw.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/sbin/nft delete table ip cve_2026_98432
ExecStart=/usr/sbin/nft -f /etc/cve-2026-98432.nft
ExecStop=/usr/sbin/nft delete table ip cve_2026_98432

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cve-2026-98432.service


sysctl -w net.mptcp.enabled=0
echo "net.mptcp.enabled = 0" > /etc/sysctl.d/99-disable-mptcp.conf

ss -lnMp
echo "================================================================="
echo "WARNING!!! Restart all servicec from this table!"
