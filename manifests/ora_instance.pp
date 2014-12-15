# == Class: ora_rac::ora_instance
#
# Do all the stuff needed to register a new oracle inntance in a running (single node)
# RAC cluster
#
#
# === Parameters
#
# name    - The instance name
# on      - The oracle instance (probably the master instance) on which to run the sql commands
# number  - The instance number
# thread  - The instancd thread
#
# === Variables
#
#  none
#
# === Authors
#
# Bert Hajee <hajee@moretIA.com>
#
define ora_rac::ora_instance(
  $on,
  $number,
  $thread,
){

  ora_tablespace{"UNDOTBS${number}@${on}":
    contents => 'undo',
    datafile => "+${data_disk_group_name}",
  }

  ora_init_param{"SPFILE/instance_number:${name}@${on}":
    ensure => present,
    value  => $number,
  }

  ora_init_param{"SPFILE/instance_name:${name}@${on}":
    ensure => present,
    value  => $name,
  }

  ora_init_param{"SPFILE/thread:${name}@${on}":
    ensure => present,
    value  => $thread,
  }

  ora_init_param{"SPFILE/undo_tablespace:${name}@${on}":
    ensure  => present,
    value   => "UNDOTBS${number}",
    require => Ora_tablespace["UNDOTBS${number}@${on}"],
  }

  file{"/tmp/add_logfiles_${thread}.sql":
    ensure  => 'present',
    content => template('ora_rac/add_logfiles.sql.erb'),
  }

  ora_exec{"@/tmp/add_logfiles_${thread}.sql@${on}":
    require   => [
      File["/tmp/add_logfiles_${thread}.sql"],
    ]
  }

  ora_thread{"${thread}@${on}":
    ensure  => 'enabled',
    require   => [
      Ora_init_param["SPFILE/undo_tablespace:${name}@${on}"],
      Ora_exec["@/tmp/add_logfiles_${thread}.sql@${on}"],
      ]
  }

}

