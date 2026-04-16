cat analyse_auth.py

import re
import json
import argparse
from datetime import datetime, timedelta

parser = argparse.ArgumentParser()
parser.add_argument("--hours", type=int, default=24)
parser.add_argument("--file", type=str, default="auth_like.log")
args = parser.parse_args()

failed_by_ip = {}
success_by_user = {}
sudo_commands = []

now = datetime.now().astimezone()
limit = now - timedelta(hours=args.hours)

with open(args.file, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        # lire la date au début de la ligne
        parts = line.split(" ", 1)
        if len(parts) < 2:
            continue

        try:
            dt = datetime.fromisoformat(parts[0])
        except ValueError:
            continue

        if dt < limit:
            continue

        # tentatives SSH échouées
        if "Failed password" in line:
            m = re.search(r"from (\d+\.\d+\.\d+\.\d+)", line)
            if m:
                ip = m.group(1)
                failed_by_ip[ip] = failed_by_ip.get(ip, 0) + 1

        # connexions SSH réussies
        if "Accepted password for" in line:
            m = re.search(r"Accepted password for (\S+)", line)
            if m:
                user = m.group(1)
                success_by_user[user] = success_by_user.get(user, 0) + 1

        # commandes sudo
        if "sudo:" in line and "COMMAND=" in line:
            m_user = re.search(r"sudo:\s+(\S+)\s*:", line)
            m_cmd = re.search(r"COMMAND=(.*)", line)
            if m_user and m_cmd:
                sudo_commands.append({
                    "date": dt.isoformat(),
                    "user": m_user.group(1),
                    "command": m_cmd.group(1).strip()
                })

ips_over_5 = [ip for ip, count in failed_by_ip.items() if count > 5]

result = {
    "failed_ssh_by_ip_last_n_hours": failed_by_ip,
    "ips_over_5_attempts": ips_over_5,
    "successful_connections_by_user": success_by_user,
    "sudo_commands": sudo_commands
}

print(json.dumps(result, indent=4, ensure_ascii=False))
