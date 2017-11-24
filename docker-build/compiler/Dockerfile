FROM centos:7
#RUN yum -y groupinstall "Development Tools" && yum -y install cmake cpanminus  postgresql-devel which
RUN rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 && yum install -y epel-release
RUN yum install -y --setopt=tsflags=nodocs cmake make gcc-c++ perl cpanminus nmap telnet\
    pcre-devel libpqxx-devel flex flex-devel net-snmp-devel cryptopp-devel boost-devel \
    docker-client \
    && cpanm --quiet  install --no-man-pages --notest Dist::Zilla   Dist::Zilla::Plugin::PodWeaver  Pod::Weaver::Section::GenerateSection Dist::Zilla::Plugin::PodnameFromClassname \
    && yum clean  all && rm -rf /root/.cpanm
#RUN curl -sL --compressed https://git.io/cpm > /usr/bin/cpm \
#    && chmod +x /usr/bin/cpm \
#    && cpm install  -w 10 -v --no-test --global Dist::Zilla \
#    yum clean all
RUN mkdir -p /Build/{src,build}
WORKDIR /Build/build
CMD ["bash"]