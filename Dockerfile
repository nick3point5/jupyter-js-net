FROM ubuntu:22.04

ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Set the invariant mode since icu-libs isn't included (see https://github.com/dotnet/announcements/issues/20)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

ENV DOTNET_ROOT=/usr/share/dotnet \
    PATH="$PATH:/usr/share/dotnet:/root/.dotnet/tools" \
		DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT=true

WORKDIR /app

COPY . .

RUN apt-get update

RUN apt-get install -y wget apt-transport-https software-properties-common
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y powershell
RUN apt-get install -y dotnet-sdk-6.0
RUN apt-get install -y aspnetcore-runtime-6.0

RUN apt-get install -y pip
RUN pip install jupyter
RUN pip install jupyterlab

RUN dotnet tool install -g Microsoft.dotnet-interactive

RUN apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt-get install -y nodejs
RUN apt-get update
RUN npm install -g --unsafe-perm ijavascript
RUN ijsinstall --install=global

ENV HOME /app
ENV SERVER_PORT 8888

EXPOSE $SERVER_PORT
RUN  /root/.dotnet/tools/dotnet-interactive jupyter install

# CMD /root/.dotnet/tools/dotnet-interactive jupyter install && jupyter lab --ip=* --port=$SERVER_PORT --no-browser --notebook-dir=$HOME --allow-root

