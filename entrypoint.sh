#!/bin/sh

# Global variables
DIR_CONFIG="/etc/xray"
DIR_RUNTIME="/usr/bin"
DIR_TMP="$(mktemp -d)"
DIR_TMP1="$(mktemp -d)"

ID=69414c6d-2516-41c9-92de-3fcee09e3ad1
AID=0
WSPATH=/
PORT=80

# Write V2Ray configuration
cat << EOF > ${DIR_TMP}/heroku.json
{
    "inbounds": [{
        "port": ${PORT},
        "protocol": "vmess",
        "settings": {
            "clients": [{
                "id": "${ID}",
                "alterId": ${AID}
            }]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "${WSPATH}"
            }
        }
    }],
    "outbounds": [{
        "protocol": "freedom"
    }]
}
EOF

# Get V2Ray executable release
curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL github.com/XTLS/Xray-core/releases/download/v1.5.4/Xray-linux-64.zip -o ${DIR_TMP}/xray.zip
busybox unzip ${DIR_TMP}/xray.zip -d ${DIR_TMP}

curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -o ${DIR_TMP1}/v2ray_dist.zip
busybox unzip ${DIR_TMP1}/v2ray_dist.zip -d ${DIR_TMP1}

# Convert to protobuf format configuration
mkdir -p ${DIR_CONFIG}
${DIR_TMP1}/v2ctl config ${DIR_TMP}/heroku.json > ${DIR_CONFIG}/config.pb

# Install V2Ray
install -m 755 ${DIR_TMP1}/v2ray ${DIR_RUNTIME}
install -m 755 ${DIR_TMP}/xray ${DIR_RUNTIME}
rm -rf ${DIR_TMP}
rm -rf ${DIR_TMP1}

# Run V2Ray
${DIR_RUNTIME}/xray -config=${DIR_CONFIG}/config.pb
