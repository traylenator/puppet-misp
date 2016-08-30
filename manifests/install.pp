
class misp::install inherits misp {

  require '::misp::dependencies'

  # MISP

  vcsrepo { '/var/www/MISP/':
    ensure     => present,
    provider   => git,
    submodules => true,
    force      => false,
    source     => 'git://github.com/MISP/MISP.git',
    revision   => $misp::git_tag,
  }

  exec {'git ignore permissions':
    command     => '/usr/bin/git config core.filemode false',
    cwd         => '/var/www/MISP/',
    refreshonly => true,
    subscribe   => Vcsrepo['/var/www/MISP/'],
    notify      => Exec['git clone python-cybox','git clone python-stix', 'CakeResque curl'],
  }

  exec {'git clone python-cybox':
    command     => '/usr/bin/git clone https://github.com/CybOXProject/python-cybox.git',
    cwd         => '/var/www/MISP/app/files/scripts/',
    refreshonly => true,
    unless      => '/usr/bin/ls -d /var/www/MISP/app/files/scripts/python-cybox',
    notify      => Exec['python-cybox config'],
  }

  exec {'git clone python-stix':
    command     => '/usr/bin/git clone https://github.com/STIXProject/python-stix.git',
    cwd	        => '/var/www/MISP/app/files/scripts/',
    refreshonly	=> true,
    unless      => '/usr/bin/ls -d /var/www/MISP/app/files/scripts/python-stix',
    notify      => Exec['python-stix config'],
  }

  exec {'python-cybox config':
    command     => '/usr/bin/git checkout v2.1.0.12 && /usr/bin/git config core.filemode false && /usr/bin/python setup.py install',
    cwd         => '/var/www/MISP/app/files/scripts/python-cybox/',
    unless      => '/usr/bin/pip list | grep cybox',
    umask       => '0022',
    refreshonly => true,
  }

  exec {'python-stix config':
    command     => '/usr/bin/git checkout v1.1.1.4 && /usr/bin/git config core.filemode false && /usr/bin/python setup.py install',
    cwd         => '/var/www/MISP/app/files/scripts/python-stix/',
    unless      => '/usr/bin/pip list | grep stix',
    umask       => '0022',
    refreshonly => true,
  }

  # CakePHP

  #CakePHP

  exec {'CakeResque curl':
    command     => '/usr/bin/curl -s https://getcomposer.org/installer | php',
    cwd         => '/var/www/MISP/app/',
    environment => ['COMPOSER_HOME=/var/www/MISP/app/'],
    refreshonly => true,
    notify      => Exec['CakeResque kamisama'],
  }

  exec {'CakeResque kamisama':
    command     => '/usr/bin/php composer.phar require kamisama/cake-resque:4.1.2',
    cwd         => '/var/www/MISP/app/',
    environment => ['COMPOSER_HOME=/var/www/MISP/app/'],
    refreshonly => true,
    notify      => Exec['CakeResque config'],
  }

  exec {'CakeResque config':
    command     => '/usr/bin/php composer.phar config vendor-dir Vendor',
    cwd         => '/var/www/MISP/app/',
    environment => ['COMPOSER_HOME=/var/www/MISP/app/'],
    refreshonly => true,
    notify      => Exec['CakeResque install'],
  }

  exec {'CakeResque install':
    command     => '/usr/bin/php composer.phar install',
    environment => ['COMPOSER_HOME=/var/www/MISP/app/'],
    cwd         => '/var/www/MISP/app/',
    refreshonly => true,
    notify      => File['/etc/opt/rh/rh-php56/php-fpm.d/redis.ini', '/etc/opt/rh/rh-php56/php-fpm.d/timezone.ini'],
  }

  file {'/etc/opt/rh/rh-php56/php-fpm.d/redis.ini':
    ensure  => file,
    content => 'extension=redis.so',
  }

  file {'/etc/opt/rh/rh-php56/php.d/99-redis.ini':
    ensure    => link,
    target    => '/etc/opt/rh/rh-php56/php-fpm.d/redis.ini',
    subscribe => File['/etc/opt/rh/rh-php56/php-fpm.d/redis.ini'],
  }

  file {'/etc/opt/rh/rh-php56/php-fpm.d/timezone.ini':
    ensure  => file,
    content => 'date.timezone = \'Europe/Zurich\'',
  }

  file {'/etc/opt/rh/rh-php56/php.d/99-timezone.ini':
    ensure    => link,
    target    => '/etc/opt/rh/rh-php56/php-fpm.d/timezone.ini',
    subscribe => File['/etc/opt/rh/rh-php56/php-fpm.d/timezone.ini'],
  }

  file { '/var/www/MISP/app/Plugin/CakeResque/Config/config.php':
    ensure    => file,
    owner     => 'root',
    group     => 'apache',
    source    => 'file:///var/www/MISP/INSTALL/setup/config.php',
    subscribe => Exec['CakeResque install'],
  }
}