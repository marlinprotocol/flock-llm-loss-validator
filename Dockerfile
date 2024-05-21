# FROM python:3.11.9-slim-bullseye AS builder
# RUN apt-get update && apt-get install -y build-essential
# WORKDIR /app
# COPY requirements.txt .
# RUN pip3 install --no-cache-dir -r requirements.txt

# # Stage 2: Runtime environment
# FROM python:3.11.9-slim-bullseye
# WORKDIR /app
# COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# COPY --from=builder /usr/local/bin /usr/local/bin
# COPY . .
# CMD ["python", "validate.py", "loop", "--task_id", "$task_id", "--validation_args_file", "validation_config_cpu.json.example"]


# FROM python:3.11.9-slim-bullseye

# WORKDIR /app

# # Copy the requirements file
# COPY requirements.txt .

# # Copy the application code
# COPY ./src /app

# # Command to install dependencies at runtime and run the application
# CMD ["sh", "-c", "pip3 install --no-cache-dir -r requirements.txt && python ./validate.py loop --task_id $task_id --validation_args_file validation_config_cpu.json.example"]


# base image
FROM python:3.11.9-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# install dependency tools
RUN apt-get update -y && apt-get install apt-utils -y && apt-get install net-tools iptables iproute2 wget -y && apt-get autoclean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

# working directory
WORKDIR /app

# supervisord to manage programs
RUN wget -O supervisord http://public.artifacts.marlin.pro/projects/enclaves/supervisord_master_linux_amd64
RUN chmod +x supervisord

# transparent proxy component inside the enclave to enable outgoing connections
RUN wget -O ip-to-vsock-transparent http://public.artifacts.marlin.pro/projects/enclaves/ip-to-vsock-transparent_v1.0.0_linux_amd64
RUN chmod +x ip-to-vsock-transparent

# key generator to generate static keys
RUN wget -O keygen http://public.artifacts.marlin.pro/projects/enclaves/keygen_v1.0.0_linux_amd64
RUN chmod +x keygen

# attestation server inside the enclave that generates attestations
RUN wget -O attestation-server http://public.artifacts.marlin.pro/projects/enclaves/attestation-server_v1.0.0_linux_amd64
RUN chmod +x attestation-server

# proxy to expose attestation server outside the enclave
RUN wget -O vsock-to-ip http://public.artifacts.marlin.pro/projects/enclaves/vsock-to-ip_v1.0.0_linux_amd64
RUN chmod +x vsock-to-ip

# dnsproxy to provide DNS services inside the enclave
RUN wget -O dnsproxy http://public.artifacts.marlin.pro/projects/enclaves/dnsproxy_v0.46.5_linux_amd64
RUN chmod +x dnsproxy

# your custom setup goes here
COPY requirements.txt .
COPY ./src /app

RUN pip3 install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html

# supervisord config
COPY supervisord.conf /etc/supervisord.conf

# setup.sh script that will act as entrypoint
COPY setup.sh ./
RUN chmod +x setup.sh

# entry point
ENTRYPOINT [ "/app/setup.sh" ]
