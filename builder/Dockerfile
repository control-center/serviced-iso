FROM centos:7.2.1511

#COPY get_pkg_updates.sh /
#RUN sh get_pkg_updates.sh
COPY centos7-rpms.tar.gz /centos7-rpms.tar.gz
ADD http://artifacts.zenoss.eng/isos/CentOS-7-x86_64-Minimal-1511.iso /centos.iso
RUN yum install -y wget mkisofs yum-utils createrepo
COPY isolinux.cfg /
COPY zenoss-5-ks.cfg /
COPY makeiso.sh /
CMD /bin/bash /makeiso.sh
