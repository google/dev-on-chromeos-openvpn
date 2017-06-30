# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build an openvpn server and PKI insfrastructure optimized for use with a
# ChromeOS system.

FROM kylemanna/openvpn

RUN apk update && \
    apk add supervisor certbot expect util-linux coreutils dnsmasq

ENV PUBLIC_HOSTNAME=foo.example.com
ENV ADMIN_EMAIL=admin@example.com
ENV CERTBOT_STAGING_FLAG=--staging

VOLUME /etc/letsencrypt
VOLUME /etc/openvpn
VOLUME /etc/dnsmasq.d

EXPOSE 443
EXPOSE 1194

COPY src/openvpn.sh /asacamano/openvpn/openvpn.sh
COPY src/openvpn.pki.expect /asacamano/openvpn/openvpn.pki.expect
COPY src/openvpn.client.expect /asacamano/openvpn/openvpn.client.expect
COPY src/openvpn.onc.sh /asacamano/openvpn/openvpn.onc.sh
COPY src/supervisord.config /asacamano/openvpn/supervisord.config
COPY src/openvpn_check_password.sh /asacamano/openvpn/check_password.sh
ENTRYPOINT ["/asacamano/openvpn/openvpn.sh"]
