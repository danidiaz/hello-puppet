stage { 'req-install': before => Stage['rvm-install'] }  

class requirements {
  group { "puppet": ensure => "present", }
  exec { "apt-update":
    command => "/usr/bin/apt-get -y update"
  }
}

File { owner => 0, group => 0, mode => 0644 }

class installrvm {
  include rvm
  rvm::system_user { vagrant: ; }
}
  
class installruby {
    rvm_system_ruby {
      'ruby-1.9.3':
        ensure => 'present';
    }
}

class doinstall {
  class { requirements:, stage => "req-install" }
  class { installrvm: }
  class { installruby: require => Class[Installrvm] }

  rvm_gem {
    'net-sftp':
      name => 'net-sftp',
      ruby_version => 'ruby-1.9.3',
      require => Rvm_system_ruby['ruby-1.9.3']
  }
}

include doinstall

package {
      [
      'smbclient',
      'cvs',
      'x11-apps',
      'x11-utils',
      'xfonts-base',
      'xterm',
      'xvfb',
      'vim',
      'tmux'
      ]:
      ensure => installed,
  }

package {
  'python-software-properties':
      ensure => installed,
}

exec { 'add-wan-repo':
  command => 'sudo add-apt-repository "deb http://opensource.wandisco.com/ubuntu lucid svn17"',
  path  => "/usr/bin/",
  unless => '/bin/grep "lucid svn17" /etc/apt/sources.list',
  require => Package['python-software-properties'],
}

exec { 'add-wan-repo-key':
  command => 'sudo /usr/bin/wget -q http://opensource.wandisco.com/wandisco-debian.gpg -O- | sudo apt-key add -',
  path  => "/usr/bin/",
  refreshonly => true,
}

exec { 'add-wan-repo-update':
  command => '/usr/bin/apt-get -y update',
  refreshonly => true,
}

Exec['add-wan-repo'] ~> Exec['add-wan-repo-key'] ~> Exec['add-wan-repo-update'] # ~ is for notifications

package {
  'subversion':
      ensure => 'installed',
      require => Exec['add-wan-repo-update'] # requires on exec always seem to work, even if the execs aren't executed...
}

# oracle jdk
# adapted from here: http://architects.dzone.com/articles/puppet-installing-oracle-java
exec { 'add-java-repo':
  command => 'sudo add-apt-repository ppa:webupd8team/java',
  path  => "/usr/bin/",
  creates => '/etc/apt/sources.list.d/webupd8team-java-lucid.list',
  require => Package['python-software-properties'],
  notify => Exec["add-java-repo-update","set-java-licence-selected","set-java-licence-seen"],
}

exec { 
   'add-java-repo-update':
      command => '/usr/bin/apt-get -y update',
      refreshonly => true;

   'set-java-licence-selected':
     command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/sudo /usr/bin/debconf-set-selections',
     refreshonly => true; 

   'set-java-licence-seen':
     command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/sudo /usr/bin/debconf-set-selections',
     refreshonly => true; 
}

package { 'oracle-java6-installer':
   ensure => 'installed',
   require => Exec["add-java-repo-update","set-java-licence-selected","set-java-licence-seen"],
}

package { 'oracle-java6-set-default':
   ensure => 'installed',
   require => Package['oracle-java6-installer'],
}

