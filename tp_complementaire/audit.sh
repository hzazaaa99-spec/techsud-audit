cat audit.sh

#!/bin/bash

echo "=== AUDIT $(date) ===" >> /var/log/audit_auto.log

# 1. UFW
sudo ufw status | grep -q active && echo "UFW OK" >> /var/log/audit_auto.log || echo "UFW KO" >> /var/log/audit_auto.log

# 2. Fail2ban
systemctl is-active --quiet fail2ban && echo "Fail2ban OK" >> /var/log/audit_auto.log || echo "Fail2ban KO" >> /var/log/audit_auto.log

# 3. SSH pas sur 22
SSH_PORT=$(grep -E '^Port ' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)
if [ "$SSH_PORT" = "22" ] || [ -z "$SSH_PORT" ]; then
    echo "SSH sur 22 (KO)" >> /var/log/audit_auto.log
else
    echo "SSH OK (port $SSH_PORT)" >> /var/log/audit_auto.log
fi

# 4. root SSH désactivé
grep -Eq '^PermitRootLogin no' /etc/ssh/sshd_config && echo "Root SSH OK" >> /var/log/audit_auto.log || echo "Root SSH KO" >> /var/log/audit_auto.log

# 5. MariaDB sur 127.0.0.1 uniquement
grep -R "127.0.0.1" /etc/mysql/ > /dev/null 2>&1 && echo "MariaDB OK" >> /var/log/audit_auto.log || echo "MariaDB KO" >> /var/log/audit_auto.log

# 6. Mises à jour de sécurité disponibles
apt list --upgradable 2>/dev/null | grep -i security > /dev/null && echo "Updates sécurité dispo (KO)" >> /var/log/audit_auto.log || echo "Pas d'updates sécurité (OK)" >> /var/log/audit_auto.log

# 7. Processus en écoute sur des ports inattendus
sudo ss -tuln | grep -E 'LISTEN' | grep -v ':80 ' | grep -v ':2222 ' | grep -v '127.0.0.1:3306' > /dev/null && echo "Ports inattendus détectés (KO)" >> /var/log/audit_auto.log || echo "Pas de ports inattendus (OK)" >> /var/log/audit_auto.log

# 8. Fichiers modifiés dans /etc dans les dernières 24h
find /etc -type f -mtime -1 | grep . > /dev/null && echo "Fichiers récents dans /etc (à vérifier)" >> /var/log/audit_auto.log || echo "Pas de modif récente dans /etc" >> /var/log/audit_auto.log
