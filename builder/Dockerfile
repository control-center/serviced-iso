FROM centos:7

ADD http://mirror.rackspace.com/CentOS/7/isos/x86_64/CentOS-7-x86_64-Minimal-1511.iso /centos.iso
RUN yum install -y wget mkisofs yum-utils createrepo
COPY isolinux.cfg /
COPY zenoss-5-ks.cfg /
COPY makeiso.sh /
CMD /bin/bash /makeiso.sh
