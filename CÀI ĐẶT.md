# 4.Cài đặt Cobbler trên Centos 7

# MỤC LỤC
  - [4.1.Mô hình](#41mô-hình)
  - [4.2.Cài đặt và cấu hình Cobbler](#42cài-đặt-và-cấu-hình-cobbler)
    - [4.2.1.Cài đặt EPEL-repo](#421cài-đặt-epel-repo)
    - [4.2.2.Cài đặt Cobbler và các package cần thiết](#422cài-đặt-cobbler-và-các-package-cần-thiết)
    - [4.2.3.Kích hoạt các dịch vụ](#423kích-hoạt-các-dịch-vụ)
    - [4.2.4.Cấu hình Cobbler](#424cấu-hình-cobbler)
    - [4.2.5.Truy cập vào giao diện Web](#425truy-cập-vào-giao-diện-web)
    - [4.2.6.Chú ý](#426chú-ý)
  - [4.3.Scripts cài đặt Cobbler trên Centos 7](#43scripts-cài-đặt-cobbler-trên-centos-7)



## 4.1.Mô- h.ình : fg
<img src="../images/cai-dat-cobbler-centos7-1.png" />

\- Bài lab thực hiện trên server cài đặt ảo hóa qemu-kvm với Cobbler, Client 1 và Client 2 là các máy ảo.  
\- Chú ý tắt DHCP server của mạng `172.16.69.0/24`.  



## 4.2.Cài đặt và cấu hình Cobbler
### 4.2.1.Cài đặt EPEL-repo
\- Epel-repo (Extra Packages for Enterprise Linux) là một dự án repository từ Fedora team cung cấp rất nhiều gói add-on package mà chúng ta thường dùng cho các bản Linux bao gồm CentOS, RHEL (Red Hat Enterprise Linux) và Scientific Linux.  
Cài đặt Epel-repo thực hiện lệnh sau:  
```
yum update -y
yum install epel-release
```

### 4.2.2.Cài đặt Cobbler và các package cần thiết
\- Cài các package cần thiết:  
```
yum install cobbler cobbler-web dnsmasq syslinux xinetd bind bind-utils dhcp debmirror pykickstart fence-agents-all -y
```

Trong đó:  
\- `cobbler`, `cobbler-web`: các gói phần mềm cài đặt chạy dịch vụ cobbler và giao diện web của cobbler.  
\- `dnsmasq`, `bind`, `bind-utils`, `dhcp` : các gói phần mềm chạy dịch vụ quản lý DNS và quản lý DHCP cho các máy client boot OS từ cobbler.  
\- `syslinux` : là một chương trình bootloader và tiện ích cho phép đẩy vào client cho phép client boot OS qua mạng. (trong trường hợp này nó được gọi là pxelinux)  
\- `xinetd`: chịu trách nhiệm tạo socket kết nối với máy client. Dựa vào cổng và giao thức (tcp hay udp) nó biết được phải trao đổi dữ liệu mà nó nhận được với back-end nào dựa vào thuộc tính server trong file cấu hình. Được sử dụng để quản lý và tạo socket cho TFTP server truyền file boot cho client.  
\- `debmirror`: gói phần mềm cài đặt cho phép tạo một mirror server chứa các gói phần mềm cài đặt của các distro trên một server local (ở đây cài luôn lên cobbler)  
\- `pykickstart` : thư việc python cho phép đọc và chỉnh sửa nội dung file kickstart, hỗ trợ cobbler chỉnh sửa file kickstart thông qua giao diện web.  
\- `fence-agents-all` : Red Hat fence agents are a collection of scripts to handle remote power management for cluster devices. They allow failed or unreachable cluster nodes to be forcibly restarted and removed from the cluster.  

### 4.2.3.Kích hoạt các dịch vụ
\- Kích hoạt và khởi động các dịch vụ cobblerd và httpd:  
```
systemctl start cobblerd
systemctl enable cobblerd
systemctl start httpd
systemctl enable httpd
```

\- Disable SELinux:  
- Tìm dòng `SELINUX=enforcing` trong 2 file `/etc/sysconfig/selinux` và `/etc/selinux/config` sửa thành:  
```
SELINUX=disabled
```

hoặc thực hiện các lệnh sau:  
```
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
```

- Thực hiện lệnh:  
```
setenforce 0
```

\- Khởi động lại máy và thực hiện bước tiếp theo.  
Thực hiện các lệnh sau nếu OS chạy firewall:  
```
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --add-service=dhcp --permanent
firewall-cmd --add-port=69/tcp --permanent
firewall-cmd --add-port=69/udp --permanent
firewall-cmd --add-port=4011/udp --permanent
firewall-cmd --reload
```

### 4.2.4.Cấu hình Cobbler
\- **Thực hiện sửa file cấu hình của Cobbler, file cấu hình `Cobbler /etc/cobbler/settings`:**  
- Cấu hình password mặc định để tăng bảo mật cho hệ thống. Sử dụng openssl để sinh ra mật khẩu đã được mã hóa như sau:  
```
openssl passwd -1
Password: <enter_password_here>
Verifying - Password: <reenter_password_here>
$1$JSjhSHV4$m2FbLHTeCIwHXFGet3UvI.
```

- Sửa file `/etc/cobbler/settings` với các thông số `default_password_crypted` với password đã được mã hóa vừa sinh ra ở trên, và cập nhật các thông số của DHCP, DNS, PXE từ 0 lên 1 như sau:  

  - Thay thế mật khẩu vừa tạo vào mật khẩu mặc định:  
  ```
  default_password_crypted: "$1$JSjhSHV4$m2FbLHTeCIwHXFGet3UvI."
  ```

  Đoạn password này được sử dụng để làm password mặc định cho client khi được cấu hình trong file kickstart sử dụng với tùy chọn `--iscrypted`  
  Ví dụ:  
  ```
  #Root password
  rootpw --iscrypted $default_password_crypted
  ```

  Khi đó, các client khi boot lên sẽ có password như đã cấu hình. Việc này nhằm mục đích tăng tính bảo mật, không cho người khác thấy rõ được password của bạn.  

  - Để thực hiện boot PXE, người quản trị cần một DHCP server để cấp phát IP và chuyển hướng trực tiếp client boot tới TFTP server nơi mà nó có thể download các file boot. Cobbler có thể quản lý và thực hiện việc này, và đồng thời quản lý dịch vụ DNS (nếu có, tuy nhiên vẫn cần cấu hình) thông qua sửa đồi thông số `manage_dhcp` và `manage_dns`(cho phép dịch vụ DHCP, DNS chạy local trên máy server). Thực hiện sửa đổi bằng lệnh như sau:  
  ```
  sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
  sed -i 's/manage_dns: 0/manage_dns: 1/g' /etc/cobbler/settings
  ```
  
  - Kích hoạt cho phép boot các file cấu hình cài đặt OS qua card mạng  
  ```
  sed -i 's/pxe_just_once: 0/pxe_just_once: 1/g' /etc/cobbler/settings
  ```

  - Chỉnh sửa IP của TFTP server (next_server) và IP của Cobbler (server). Thực hiện các lệnh sau:  
  ```
  sed -i 's/next_server: 127.0.0.1/next_server: 172.16.69.21/g' /etc/cobbler/settings
  sed -i 's/server: 127.0.0.1/server: 172.16.69.21/g' /etc/cobbler/settings
  ```

  Trong đó, `server` là địa chỉ IP của cobbler server (lưu ý: không nên sử dụng địa chỉ `0.0.0.0`, nên sử dụng địa chỉ IP mà bạn muốn các client sử dụng để liên lạc với cobbler server với các giao thức như http, tftp), `next_server` là địa chỉ IP của TFTP server mà các file boot (kernel, initrd) được lấy về. Thường thì sẽ thiết lập cho cùng là Cobbler server.

- **Cập nhật file cấu hình DHCP và DNSMASQ**  
Phần này thực hiện cấu hình dải DHCP cho phép Cobbler cấp phát cho Client, và thông tin về các file pxelinux.0 gửi về cho client . Ở đây, cho phép trong dải từ `172.16.69.100` tới `172.16.69.200`.  
  - Sửa file cấu hình của DHCP như sau `/etc/cobbler/dhcp.template` :  
  ```
  [. . .]
   subnet 172.16.69.0 netmask 255.255.255.0 {
       option routers             172.16.69.1;
       option domain-name-servers 8.8.8.8;
       option subnet-mask         255.255.255.0;
       range dynamic-bootp        172.16.69.100 172.16.69.200;
       default-lease-time         21600;
       max-lease-time             43200;
       next-server                $next_server; #vi tri cua TFTP server (trong TH nay chinh la cobbler)
       class "pxeclients" {
            match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
            if option pxe-system-type = 00:02 {
                    filename "ia64/elilo.efi";
            } else if option pxe-system-type = 00:06 {
                    filename "grub/grub-x86.efi";
            } else if option pxe-system-type = 00:07 {
                    filename "grub/grub-x86_64.efi";
            } else if option pxe-system-type = 00:09 {
                    filename "grub/grub-x86_64.efi";
            } else {
                    filename "pxelinux.0";
            }
       }
  
  }
  ```

  - Cập nhật dải địa chỉ IP được cấp phát cho client trong file `/etc/cobbler/dnsmasq.template` như sau:  
  ```
  [...]
  dhcp-range=172.16.69.100, 172.16.69.200
  ```

  - Sửa `disable = yes` thành `disable = no` trong file `/etc/xinetd.d/tftp`  :  
  ```
  [. . .]
  service tftp
  {
          socket_type             = dgram
          protocol                = udp
          wait                    = yes
          user                    = root
          server                  = /usr/sbin/in.tftpd
          server_args             = -s /var/lib/tftpboot
          disable                 = yes
          per_source              = 11
          cps                     = 100 2
          flags                   = IPv4
  }
  ```

  - Thực hiện comment `@dists="sid";` và `@arches="i386";`   trong file `/etc/debmirror.conf` để hỗ trợ các distro debian:  

  <img src="../images/cai-dat-cobbler-centos7-2.png" />

\- Khởi động lại và kích hoạt các dịch vụ sau, sau đó đồng bộ lại cobbler dùng các lệnh sau:  
```
systemctl enable rsyncd.service
systemctl restart rsyncd.service
systemctl restart cobblerd
systemctl restart xinetd
systemctl enable xinetd

cobbler get-loaders
cobbler check
cobbler sync
systemctl enable dhcpd
```

### 4.2.5.Truy cập vào giao diện Web
Sau khi hoàn thành các bước trên, truy cập vào giao diện web của Cobbler như sau (lưu ý: sử dụng `https`):  
```
https://172.16.69.21/cobbler_web/
```

<img src="../images/cai-dat-cobbler-centos7-3.png" />

Đăng nhập với tài khoản mặc định có username là `cobbler`, mật khẩu là `cobbler` .

### 4.2.6.Chú ý
\- Nếu Centos server, đã cài `libvirt` và có một vào mạng được tạo. Ta cần phải xóa tất cả các mạng đó, để tránh xung đột với `dnsmasq` do `libvirt` quản lý.  
\- Muốn restart lại dịch vụ **cobbler**, sử dụng lệnh:  
```
systemctl restart cobblerd
```


## 4.3.Scripts cài đặt Cobbler trên Centos 7
\- File `cobbler-install.sh`, link: [Scripts cài Cobbler trên Centos 7](../scripts/cobbler-install.sh)  
\- Hướng dẫn sử dụng. Thực hiện các lệnh sau với quyền `root` :  
- Set quyền cho file bash shell:  
```
chmod 755 cobbler-install.sh
```

- Thay đổi giá trị của biến trong file bash shell sao cho phù hợp mô hình.  
- Thực hiện lệnh sau để hoàn tất:  
```
bash cobbler-install.sh
```



