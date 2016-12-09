FROM centos:7.2.1511

RUN yum install -y wget mkisofs yum-utils createrepo
COPY isolinux.cfg /
COPY zenoss-5-ks.cfg /
COPY makeiso.sh /
#
# /build is the directory that makeiso.sh expects to contain the ISO and tarball of RPMs
RUN mkdir -p /mnt/build
#
# /output is the directory that makeiso.sh will write the final ISO to
RUN mkdir -p /mnt/output

CMD /bin/bash /makeiso.sh
