Postfix
=======
安装过程:

1、下载安装包放到你的安装目录，比如/root

2、su

3、cd /root

4、tar xvfz postfix.tar.gz

5、cd postfix

6、./postfix.sh

根据提示输入管理员邮件帐号名称，
postfix的mysql的数据库帐号和密码，
安装完成后浏览器进入
http://www.yourdomain.com/postfixadmin/
就可以用管理员帐号（密码admin，进入后修改）管理了，
可以随意添加域名和里面的邮件账户，
如果要设置转发，
可以以设置的mysql的数据库帐号和密码进入postfix数据库，
设置alias表的goto字段即可

服务器设置：将mail.domain1.com，mail.domain2.com...解析到你服务器的IP地址

客户端设置

接收服务器和发送服务器：mail.domain.com

用户名：youraccount@domain.com
(必须是邮件地址，而不是youraccount)

密码：yourpassword
发送选项：服务器需要验证

该邮件系统仅支持pop3，如果要想支持imap，你可能需要修改postfix.sh安装脚本，重新安装，请自己琢磨
