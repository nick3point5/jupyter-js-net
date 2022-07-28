FROM jupyter/base-notebook:latest

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

WORKDIR ${HOME}

USER root

# Install nodejs
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN conda remove nodejs
RUN apt-get purge --auto-remove nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential checkinstall
RUN npm install -g node-gyp
RUN npm install -g --unsafe-perm ijavascript
RUN ijsinstall --install=global


ENV \
  # Enable detection of running in a container
  DOTNET_RUNNING_IN_CONTAINER=true \
  # Enable correct mode for dotnet watch (only mode supported in a container)
  DOTNET_USE_POLLING_FILE_WATCHER=true \
  # Skip extraction of XML docs - generally not useful within an image/container - helps performance
  NUGET_XMLDOC_MODE=skip \
  # Opt out of telemetry until after we install jupyter when building the image, this prevents caching of machine id
  DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT=true

# Install .NET CLI dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libc6 \
  libgcc1 \
  libgssapi-krb5-2 \
  libicu66 \
  libssl1.1 \
  libstdc++6 \
  zlib1g \
  && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK

# When updating the SDK version, the sha512 value a few lines down must also be updated.
ENV DOTNET_SDK_VERSION 6.0.100

RUN dotnet_sdk_version=6.0.100 \
  && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
  && dotnet_sha512='cb0d174a79d6294c302261b645dba6a479da8f7cf6c1fe15ae6998bc09c5e0baec810822f9e0104e84b0efd51fdc0333306cb2a0a6fcdbaf515a8ad8cf1af25b' \
  && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
  && mkdir -p /usr/share/dotnet \
  && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
  && rm dotnet.tar.gz \
  && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
  # Trigger first run experience by running arbitrary cmd
  && dotnet help

# Copy notebooks
COPY . ${HOME}/Notebooks/

# Add package sources
RUN echo "\
  <configuration>\
  <solution>\
  <add key=\"disableSourceControlIntegration\" value=\"true\" />\
  </solution>\
  <packageSources>\
  <clear />\
  <add key=\"dotnet-experimental\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-experimental/nuget/v3/index.json\" />\
  <add key=\"dotnet-public\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-public/nuget/v3/index.json\" />\
  <add key=\"dotnet-eng\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-eng/nuget/v3/index.json\" />\
  <add key=\"dotnet-tools\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json\" />\
  <add key=\"dotnet-libraries\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-libraries/nuget/v3/index.json\" />\
  <add key=\"dotnet5\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet5/nuget/v3/index.json\" />\
  <add key=\"MachineLearning\" value=\"https://pkgs.dev.azure.com/dnceng/public/_packaging/MachineLearning/nuget/v3/index.json\" />\
  </packageSources>\
  <disabledPackageSources />\
  </configuration>\
  " > ${HOME}/NuGet.config

# Install Mongo db
RUN apt-get install gnupg wget
RUN wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
RUN apt-get update
RUN apt-get install -y mongodb-org


RUN chown -R ${NB_UID} ${HOME}
USER ${USER}

#Install nteract 
RUN pip install nteract_on_jupyter

# Install lastest build of Microsoft.DotNet.Interactive
RUN dotnet tool install -g Microsoft.dotnet-interactive --add-source "https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-experimental/nuget/v3/index.json"

ENV PATH="${PATH}:${HOME}/.dotnet/tools"
RUN echo "$PATH"

# Install kernel specs
RUN dotnet interactive jupyter install

# Enable telemetry once we install jupyter for the image
ENV DOTNET_INTERACTIVE_CLI_TELEMETRY_OPTOUT=false


# Set root to Notebooks
WORKDIR ${HOME}/Notebooks/
