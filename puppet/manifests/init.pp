stage { 'req-install': before => Stage['rvm-install'] }  

class requirements {
  group { "puppet": ensure => "present", }
  exec { "apt-update":
    command => "/usr/bin/apt-get -y update"
  }
}

File { owner => 0, group => 0, mode => 0644 }

file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine!
              Managed by Puppet.\n"
}

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

