# MENG - Server Management Script

A unified bash script for deployment, SSH connections, and server management. Built to eliminate repetitive `scp` and `ssh` commands with a clean, reliable interface.

## Why MENG?

**The Problem:** Constantly typing long deployment commands like:
```
go build -o myapp
scp myapp user@192.168.1.100:/home/user/apps/
ssh user@192.168.1.100
```

**The Solution:** One simple command that handles building, copying, and connecting:

```
./meng.sh -alias myserver -action deploy
```

## Quick Start

1. **Clone and make executable:**
```
git clone <your-repo-url>
cd Meng-Script
chmod +x meng.sh
```

2. **Configure your servers** by editing the aliases section in `meng.sh`:
```
declare -A aliases=(
[myserver]="user@192.168.1.100:/path/to/deploy/"
[staging]="deploy@staging.company.com:/var/www/"
[production]="admin@prod.company.com:/opt/apps/"
)
```

3. **Start using it:**
```
./meng.sh -action list                            Show available servers

./meng.sh -alias myserver -action ssh             Connect to server

./meng.sh -alias myserver -action scp -file myapp
Send file to server

./meng.sh -alias myserver -action deploy          Build and deploy
```