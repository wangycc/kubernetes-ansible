docker ps  | awk '{print $2}' | awk -F"/" '{print $NF}' | awk -F":" '{print $1}' | grep -v -E "pause-amd64|filebeat"
