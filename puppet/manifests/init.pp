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
  command => '/usr/bin/sudo /usr/bin/add-apt-repository "deb http://opensource.wandisco.com/ubuntu lucid svn17"',
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
