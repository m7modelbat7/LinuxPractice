# this is where I practice Linux
---
# Linux Commands Practice

## File Commands
- ls: list files
- cd: change directory
- pwd: show current path

## Text Processing
- cat /etc/passwd
- grep "bash" /etc/passwd
- cut -d: -f1 /etc/passwd
- awk -F: '{print $1, $3, $7}' /etc/passwd

## Permissions
- chmod +x script.sh

## Git Commands
- git add .
- git commit -m "add linux commands"
- git push

## Service and Process Management

### Service Management with systemctl

- `systemctl enable`
- `systemctl start`
- `systemctl status`
- `systemctl kill`

### Process Monitoring

- `top`
- `htop`
- `ps`

