#!/bin/bash

# 定义需要修改的文件
NGINX_CONF="/etc/nginx/nginx.conf"
FORWARD_STREAM_CONF="/etc/nginx/conf.d/forward.stream"

# 检查用户是否有 root 权限
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户运行此脚本！"
  exit 1
fi

# 询问用户输入 server 和 listen 的值
read -p "请输入 server IP:port (例如 192.168.1.1:8080): " SERVER
read -p "请输入 listen port (例如 8080): " LISTEN_PORT

# 修改 nginx.conf，增加 include 语句
if grep -q 'include /etc/nginx/conf.d/*.stream;' "$NGINX_CONF"; then
  echo "Nginx 配置文件已包含 stream 文件的引用！"
else
  sed -i "/include \/etc\/nginx\/modules-enabled\/*.conf;/a include /etc/nginx/conf.d/*.stream;" "$NGINX_CONF"
  echo "已在 $NGINX_CONF 中增加 include /etc/nginx/conf.d/*.stream;"
fi

# 创建 forward.stream 配置文件
echo "创建配置文件 $FORWARD_STREAM_CONF ..."
cat <<EOF > "$FORWARD_STREAM_CONF"
stream {
    upstream backend {
        server $SERVER;
    }
    server {
        listen $LISTEN_PORT;
        proxy_connect_timeout 20s;
        proxy_timeout 5m;
        proxy_pass backend;
    }
}
EOF

# 提示用户重启 Nginx 以应用更改
echo "配置已添加到 $FORWARD_STREAM_CONF."
echo "请重启 Nginx 以应用更改：sudo systemctl restart nginx"
